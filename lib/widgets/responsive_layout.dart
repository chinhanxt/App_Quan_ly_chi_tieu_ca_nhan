import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../widgets/web_sidebar.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Responsive.isMobile(context)) {
          return mobileBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}

class AdminWebLayout extends StatelessWidget {
  final Widget child;

  const AdminWebLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      drawer: Responsive.isMobile(context) ? const WebSidebar() : null,
      body: Row(
        children: [
          if (Responsive.isDesktop(context))
            const WebSidebar(),
          
          Expanded(
            child: Column(
              children: [
                // Modern Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (!Responsive.isDesktop(context))
                        IconButton(
                          icon: const Icon(Icons.menu, color: Color(0xFF64748B)),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      if (Navigator.of(context).canPop())
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      const Text(
                        "Hệ thống Quản trị",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      // Quick Actions
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF64748B)),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFF6366F1),
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content Area
                Expanded(
                  child: ClipRRect(
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
