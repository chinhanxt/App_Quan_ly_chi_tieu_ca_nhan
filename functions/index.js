const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();
const openAiApiKey = defineSecret("OPENAI_API_KEY");
const OPENAI_MODEL = "gpt-5-mini";
const SUGGESTED_ICON_NAMES = [
  "buildingColumns",
  "creditCard",
  "wallet",
  "basketShopping",
  "mugHot",
  "gasPump",
  "taxi",
  "plane",
  "house",
  "key",
  "bolt",
  "faucet",
  "wifi",
  "mobileScreen",
  "heartPulse",
  "capsules",
  "graduationCap",
  "book",
  "gamepad",
  "music",
  "gift",
  "chartLine",
  "chartPie",
  "calculator",
  "lock",
  "ellipsis",
];
const DEFAULT_CATEGORIES = [
  "Lương",
  "Mua sắm",
  "Ăn uống",
  "Di chuyển",
  "Tiết kiệm",
];
const TRANSACTION_ITEM_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    title: { type: "string" },
    amount: { type: "number" },
    type: {
      type: "string",
      enum: ["credit", "debit"],
    },
    category: { type: "string" },
    note: { type: "string" },
    date: { type: "string" },
    time: { type: "string" },
    dateTime: { type: "string" },
    isNewCategory: { type: "boolean" },
    suggestedIcon: { type: "string" },
  },
  required: [
    "title",
    "amount",
    "type",
    "category",
    "note",
    "date",
    "time",
    "dateTime",
    "isNewCategory",
    "suggestedIcon",
  ],
};
const TRANSACTION_RESPONSE_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    status: {
      type: "string",
      enum: ["success", "error", "clarification"],
    },
    message: {
      type: "string",
    },
    success: {
      type: "boolean",
    },
    transactions: {
      type: "array",
      items: TRANSACTION_ITEM_SCHEMA,
    },
    data: {
      type: "array",
      items: TRANSACTION_ITEM_SCHEMA,
    },
  },
  required: ["status", "message", "success", "transactions", "data"],
};

exports.processAiTransaction = onCall(
  {
    secrets: [openAiApiKey],
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError(
        "unauthenticated",
        "Bạn cần đăng nhập để dùng trợ lý AI.",
      );
    }

    const input = request.data?.input;
    if (typeof input !== "string" || input.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Thiếu nội dung cần xử lý.");
    }

    const normalizedInput = input.trim();
    if (normalizedInput.length > 500) {
      throw new HttpsError(
        "invalid-argument",
        "Nội dung quá dài. Bạn hãy thử chia nhỏ tin nhắn nhé.",
      );
    }

    const categories = await getUserCategories(request.auth.uid);
    const prompt = buildSystemPrompt(categories, SUGGESTED_ICON_NAMES);

    try {
      const result = await generateOpenAIJson({
        apiKey: openAiApiKey.value(),
        prompt,
        input: normalizedInput,
      });
      return normalizeResponseShape(result);
    } catch (error) {
      logger.error("OpenAI callable failed", error);
      throw mapOpenAIError(error);
    }
  },
);

async function getUserCategories(uid) {
  const snapshot = await db.collection("users").doc(uid).get();
  const categories = [...DEFAULT_CATEGORIES];

  if (snapshot.exists) {
    const data = snapshot.data();
    const customCategories = Array.isArray(data?.customCategories)
      ? data.customCategories
      : [];

    for (const category of customCategories) {
      const name = typeof category?.name === "string" ? category.name.trim() : "";
      if (name.length > 0) {
        categories.push(name);
      }
    }
  }

  return categories;
}

function normalizeResponseShape(result) {
  const transactions = Array.isArray(result.transactions)
    ? result.transactions
    : Array.isArray(result.data)
      ? result.data
      : [];

  return {
    status: result.status || (result.success ? "success" : "clarification"),
    message: typeof result.message === "string" ? result.message : "",
    success:
      result.success === true ||
      (result.success == null && (result.status || "") === "success"),
    transactions,
    data: Array.isArray(result.data) ? result.data : transactions,
  };
}

function buildSystemPrompt(categories, iconNames) {
  const now = new Date();
  const dateStr = formatDateTime(now);

  return `
Bạn là Chuyên gia Tai chinh AI. Nhiem vu: Boc tach ngon ngu doi thuong thanh du lieu giao dich JSON.
Hom nay la: ${dateStr}. Danh muc uu tien: ${categories.join(", ")}. Icon hop le: ${iconNames.join(", ")}.

QUY TAC:
1. Neu dau vao khong phai giao dich tai chinh ro rang, hay tra ve JSON \`status:"clarification"\` va \`message\` than thien, vui ve.
2. Neu mot cau co nhieu khoan thu/chi, hay tach thanh nhieu transaction trong mang.
3. Tien: k->1.000, cu/m->1.000.000, lit->100.000, ve->500.000.
4. Sua loi viet tat (dt->Dien thoai, shp->Shopee).
5. \`type\` chi duoc la \`credit\` hoac \`debit\`.
6. \`credit\` = tien DI VAO vi/tai khoan cua nguoi noi. Vi du:
   - "luong ve 15 trieu" -> credit
   - "duoc tang 100k" -> credit
   - "duoc cho 200k" -> credit
   - "nhan thuong 500k" -> credit
   - "hoan tien 30k" -> credit
   - "thu no 2 trieu" -> credit
7. \`debit\` = tien DI RA khoi vi/tai khoan cua nguoi noi. Vi du:
   - "an sang 30k" -> debit
   - "tang me 100k" -> debit
   - "tra no 1 trieu" -> debit
   - "mua ao 200k" -> debit
   - "dong tien dien 500k" -> debit
8. Dac biet quan trong:
   - "duoc tang", "duoc cho", "nhan", "luong ve", "hoan tien", "thu no" thuong la credit.
   - "mua", "an", "uong", "tra", "tang", "cho", "dong", "nap" thuong la debit.
   - "duoc tang/duoc cho" la credit, nhung "tang ai/cho ai" la debit.
   - KHONG duoc mac dinh moi giao dich la debit.
9. Ve thoi gian:
   - Neu nguoi dung noi ro ngay/gio, phai bam theo dung thong tin do.
   - Neu chi co ngay ma khong co gio, giu gio hien tai.
   - Neu chi co gio ma khong co ngay, dung ngay hom nay.
   - Neu co khung thoi gian nhu "sang/trua/chieu/toi/dem" ma khong co gio cu the, quy doi lan luot thanh 08:00 / 12:00 / 15:00 / 19:00 / 22:00.
   - KHONG duoc tu y doi thanh 00:00 neu nguoi dung khong noi nua dem.
10. Validation:
   - Neu amount am, chuyen ve so duong va suy ra \`type\` theo nghia thu/chi.
   - Neu chi co mot giao dich va amount > 100.000.000, giu giong dieu hai huoc va yeu cau nguoi dung xac nhan lai.
11. Neu la muc moi, tu tao danh muc, chon icon phu hop nhat, dat \`isNewCategory\`: true.
12. UU TIEN schema mo rong, NHUNG van giu schema cu de app tuong thich:
{"status":"success|error|clarification","message":"...","success":true|false,"transactions":[...],"data":[...]}
13. Moi transaction nen co:
{"title":...,"amount":...,"type":"credit|debit","category":...,"note":...,"date":"${formatDate(now)}","time":"${formatTime(now)}","dateTime":"${formatDateTime(now)}","isNewCategory":...,"suggestedIcon":...}
`.trim();
}

async function generateOpenAIJson({ apiKey, prompt, input }) {
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: [
        {
          role: "system",
          content: [
            {
              type: "input_text",
              text: prompt,
            },
          ],
        },
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: `Người dùng: "${input}"`,
            },
          ],
        },
      ],
      text: {
        format: {
          type: "json_schema",
          name: "finance_transaction_response",
          strict: true,
          schema: TRANSACTION_RESPONSE_SCHEMA,
        },
      },
    }),
  });

  const payload = await response.json();
  if (!response.ok || payload.error) {
    const message = payload?.error?.message || `OpenAI API error (${response.status})`;
    const status = payload?.error?.status || "UNKNOWN";
    const details = payload?.error?.details;
    throw new Error(
      JSON.stringify({
        message,
        status,
        details,
        statusCode: response.status,
      }),
    );
  }

  const text = extractOpenAIText(payload);
  if (!text) {
    throw new Error(
      JSON.stringify({
        message: "AI không phản hồi nội dung.",
        status: "EMPTY_RESPONSE",
        statusCode: 200,
      }),
    );
  }

  return extractJson(text);
}

function extractOpenAIText(payload) {
  const outputs = Array.isArray(payload?.output) ? payload.output : [];

  for (const item of outputs) {
    if (item?.type !== "message" || !Array.isArray(item.content)) {
      continue;
    }

    const text = item.content
      .map((content) => (typeof content?.text === "string" ? content.text : ""))
      .join("")
      .trim();

    if (text) {
      return text;
    }
  }

  return "";
}

function extractJson(text) {
  const jsonStart = text.indexOf("{");
  const jsonEnd = text.lastIndexOf("}") + 1;

  if (jsonStart === -1 || jsonEnd <= jsonStart) {
    return {
      status: "error",
      success: false,
      message: "AI trả về dữ liệu không hợp lệ.",
      transactions: [],
      data: [],
    };
  }

  try {
    return JSON.parse(text.slice(jsonStart, jsonEnd));
  } catch (_) {
    return {
      status: "error",
      success: false,
      message: "AI trả về dữ liệu không hợp lệ.",
      transactions: [],
      data: [],
    };
  }
}

function mapOpenAIError(error) {
  const parsed = parseErrorPayload(error);
  const message = String(parsed.message || "");
  const lowered = message.toLowerCase();

  if (
    parsed.statusCode === 429 ||
    lowered.includes("quota exceeded") ||
    lowered.includes("rate limit") ||
    lowered.includes("insufficient_quota")
  ) {
    throw new HttpsError(
      "resource-exhausted",
      "OpenAI quota exceeded.",
      {
        retryAfterSeconds: extractRetryAfterSeconds(message),
      },
    );
  }

  if (lowered.includes("api key") && lowered.includes("invalid")) {
    throw new HttpsError(
      "failed-precondition",
      "OpenAI API key is invalid or missing.",
    );
  }

  if (parsed.statusCode === 401) {
    throw new HttpsError(
      "failed-precondition",
      "OpenAI API key is invalid or missing.",
    );
  }

  throw new HttpsError(
    "internal",
    "Không thể xử lý yêu cầu AI lúc này.",
  );
}

function parseErrorPayload(error) {
  const fallback = {
    message: error instanceof Error ? error.message : String(error),
    status: "UNKNOWN",
    statusCode: 500,
  };

  if (!(error instanceof Error)) {
    return fallback;
  }

  try {
    const parsed = JSON.parse(error.message);
    return {
      message: parsed.message || fallback.message,
      status: parsed.status || fallback.status,
      details: parsed.details,
      statusCode: parsed.statusCode || fallback.statusCode,
    };
  } catch (_) {
    return fallback;
  }
}

function extractRetryAfterSeconds(message) {
  const match = /retry in ([0-9]+(?:\.[0-9]+)?)s/i.exec(message);
  if (!match) {
    return null;
  }

  const seconds = Number.parseFloat(match[1]);
  return Number.isFinite(seconds) ? Math.ceil(seconds) : null;
}

function formatDate(date) {
  return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()}`;
}

function formatTime(date) {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function formatDateTime(date) {
  return `${formatDate(date)} ${formatTime(date)}`;
}

function pad(value) {
  return String(value).padStart(2, "0");
}
