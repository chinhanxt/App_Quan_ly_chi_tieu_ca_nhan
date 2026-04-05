## ADDED Requirements

### Requirement: Use case diagrams are described with one table per diagram
The documentation workflow SHALL provide exactly one description table for each use case diagram included in the report diagram set.

#### Scenario: A use case diagram is cataloged for reporting
- **WHEN** a use case diagram is selected from the diagram source document
- **THEN** the documentation set includes one corresponding description table for that diagram

#### Scenario: A use case description table is authored
- **WHEN** a writer prepares a table for a use case diagram
- **THEN** the table records the diagram name, diagram type, purpose, main components, described flow, and system significance

### Requirement: Class diagrams are described with one table per class or entity
The documentation workflow SHALL describe each class or class-like entity in a class diagram using its own structured attribute table.

#### Scenario: A class diagram contains multiple classes
- **WHEN** a class diagram is analyzed for documentation
- **THEN** the workflow produces one attribute table for each class or entity that must be explained in the report

#### Scenario: A class description table is authored
- **WHEN** a writer prepares a table for a class in the class diagram
- **THEN** the table lists ordered attributes with a short description for each attribute

### Requirement: ERD entities are described with one table per entity
The documentation workflow SHALL describe each ERD entity using its own structured attribute table.

#### Scenario: An ERD contains multiple entities
- **WHEN** the ERD is converted into report documentation
- **THEN** the workflow produces one table per entity rather than one generic table for the entire ERD

#### Scenario: An ERD entity table is authored
- **WHEN** a writer prepares a table for an ERD entity
- **THEN** the table uses ordered rows that include the entity attributes and a short meaning for each attribute

### Requirement: Diagram description templates match the diagram type
The documentation workflow SHALL use the functional diagram template for use case diagrams and the attribute template for class diagram or ERD entities.

#### Scenario: A use case table is created
- **WHEN** the diagram type is use case
- **THEN** the workflow uses the descriptive template with metadata and narrative fields instead of the attribute-row template

#### Scenario: A data-model table is created
- **WHEN** the diagram type is class diagram or ERD
- **THEN** the workflow uses the attribute-row template instead of the narrative use case template

### Requirement: Report updates preserve consistency between source diagrams and report tables
The documentation workflow SHALL verify that the final report tables stay consistent with the source diagram document and any intermediate data-model description files.

#### Scenario: Source diagrams are updated
- **WHEN** the diagram source document changes
- **THEN** the documentation workflow rechecks the list of required tables against the updated diagram set before report insertion

#### Scenario: Report tables are reviewed before submission
- **WHEN** the report document is finalized
- **THEN** each required use case diagram and each required class or ERD entity has a matching description table in the report materials
