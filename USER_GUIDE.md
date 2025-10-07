# Java Refactoring Tools - User Guide

## What This Tool Does

This MCP server provides AI-assisted Java code refactoring capabilities. Ask your AI assistant to analyze, explore, and refactor Java codebases using a collection of specialized tools organized into functional groups.

## Getting Started

Before refactoring, your project needs to be configured:

1. **Discover** - The tool detects your build system (Maven, Gradle, etc.)
2. **Build** - Computes the build configuration
3. **Test** - Validates everything is ready

Your AI assistant can guide you through this setup.

## Available Tool Groups

The refactoring tools are organized into 7 functional groups:

### 1. Code Explorer
**Purpose**: Find and list structural elements in your codebase

**Available Tools**:
- `queryTypes` - Search for classes, interfaces, and records
- `queryMethods` - Find methods by name or characteristics
- `queryPackages` - List packages
- `queryFiles` - Find source files
- `queryLocalVariablesWithinScope` - Find local variables
- `queryFqnToPath` - Get file paths for types or packages

**What You Can Do**:
- "Find all classes with 'User' in the name"
- "Show me methods that take zero parameters"
- "List all packages under com.example.service"
- "Find all Service.java files in my project"
- "Where is the UserService class located on disk?"
- "Show me local variables in the processOrder method"

### 2. Source Reader
**Purpose**: Get actual source code and documentation

**Available Tools**:
- `queryTypeSources` - Get source code for types
- `queryMethodSources` - Get source code for methods
- `queryDocstrings` - Get documentation/javadocs

**What You Can Do**:
- "Show me the source code for UserService and OrderService"
- "Get the implementation of the login method"
- "Show me all the javadoc comments for the Payment class"
- "Read the source code for these specific methods"

### 3. Dependency Analyzer
**Purpose**: Understand how code elements relate to each other

**Available Tools**:
- `queryTypeDependencies` - Find what a type depends on
- `queryDependentTypes` - Find what depends on a type
- `queryFootprint` - Analyze the impact footprint of types
- `queryPackagesWithFootprint` - Get dependency statistics for packages
- `queryExternalLibraries` - List external libraries used
- `queryExternalLibrariesWithDependantStatistics` - See how external libraries are used
- `queryCyclesInPackageDependencyGraph` - Find circular dependencies
- `queryMethodCallGraph` - See how methods call each other
- `queryAbstractnessInstability` - Measure package architecture quality

**What You Can Do**:
- "What does UserService depend on?"
- "What classes use the User type?"
- "Show me which packages use Spring Framework"
- "Are there any circular dependencies in my package structure?"
- "How does the processPayment method call other methods?"
- "Which packages have poor architecture metrics?"
- "What's the dependency footprint of my authentication module?"
- "Show me all external libraries and how many classes use each one"

### 4. Usage Computer
**Purpose**: Compute detailed usage patterns and call paths

**Available Tools**:
- `computeTypeUsages` - Find all variables, fields, and parameters of a specific type
- `computeTypeUsageInBulk` - Find usage for multiple types at once
- `computeCallPath` - Find call paths between methods
- `computeOverviewOfNames` - Get naming statistics

**What You Can Do**:
- "Find every place where the User type is used as a variable or field"
- "Show me usage patterns for User, Order, and Product types"
- "How can I call from the Controller to the saveUser method?"
- "What are the most common variable names in my service layer?"
- "Show me naming patterns for types used in the repository package"

### 5. Code Refactor
**Purpose**: Rename and refactor code elements

**Available Tools**:

*Single Element Operations*:
- `renameField` - Rename a field
- `renameLocalVariable` - Rename a local variable
- `renameMethod` - Rename a method
- `renameParameter` - Rename a method parameter
- `renameTypeParameter` - Rename a generic type parameter
- `renameOrMoveType` - Rename or move a class/interface/record

*Bulk Operations*:
- `bulkRenameField` - Rename multiple fields at once
- `bulkRenameLocalVariable` - Rename multiple local variables
- `bulkRenameParameter` - Rename multiple parameters
- `bulkRenameOrMoveType` - Rename or move multiple types

*Advanced Operations*:
- `clusterTypesIntoPackages` - Suggest better package organization
- `extractInterface` - Extract an interface from a class
- `impactOfExtractInterfaceRequest` - See what would happen before extracting

**What You Can Do**:
- "Rename the userName field to username in the User class"
- "Rename the getData method to getUserData"
- "Move UserService from com.example.old to com.example.new"
- "Rename userName to username in all User-related classes at once"
- "Show me better package organization based on my dependencies"
- "Extract an interface from UserService"
- "What would change if I extract an interface from OrderProcessor?"

### 6. Plan Manager
**Purpose**: Handle complex multi-stage refactorings with planning and user review

**Available Tools**:
- `computeExtractInterfacePlans` - Generate multiple interface extraction options
- `computeGlobalRenameIdentifierPlan` - Plan systematic identifier renaming
- `listPlans` - See all computed refactoring plans
- `executePlan` - Execute a selected plan
- Plus UI tools for reviewing and selecting specific steps

**What You Can Do**:
- "Generate different interface extraction options for my service classes"
- "Create a plan to rename 'data' to 'userData' everywhere in my code"
- "Show me all the refactoring plans you've generated"
- "Let me review the steps in this plan and choose which ones to execute"
- "Execute the interface extraction plan I selected"

**How It Works**:
The Plan Manager creates detailed refactoring plans, lets you review them in a web interface, select which specific steps you want, then executes only your selections. This is ideal for large-scale changes where you want fine-grained control.

### 7. Run Manager
**Purpose**: Monitor and control refactoring operations

**Available Tools**:
- `listRuns` - See all refactoring runs
- `statusOfRun` - Check the status of a running operation
- `getRunResult` - Get the results when complete
- `rejectRun` - Reject changes and discard them
- `resetRun` - Reset to try again
- `interruptRun` - Stop a long-running operation

**What You Can Do**:
- "Show me all the refactoring operations that have run"
- "What's the status of the current refactoring?"
- "Is the interface extraction finished yet?"
- "I don't want these changes, reject this run"
- "Stop the current refactoring operation"
- "Reset this run so I can try different parameters"

**How It Works**:
Large refactorings can take time. The Run Manager lets you monitor progress, and when complete, you review and approve changes through a web interface before they're permanently applied.

## How to Use These Tools

### Start with Exploration

Before refactoring, understand your code:

1. **Find what exists** (Code Explorer)
   - "Find all classes related to authentication"
   - "List all packages in the service layer"

2. **Read the code** (Source Reader)
   - "Show me the source for AuthenticationService"

3. **Understand relationships** (Dependency Analyzer)
   - "What does AuthenticationService depend on?"
   - "What classes use the User type?"

### Plan Your Changes

Use analysis tools to plan refactoring:

4. **Analyze impact** (Usage Computer, Dependency Analyzer)
   - "Find all usages of the User type"
   - "Show me the dependency footprint of this module"

5. **Check feasibility** (Code Refactor impact tools)
   - "What would happen if I extract an interface from UserService?"

### Execute Refactoring

Choose based on complexity:

**Simple changes** (Code Refactor):
- "Rename userName to username"
- "Extract an interface from UserService"

**Complex changes** (Plan Manager):
- "Generate interface extraction plans for all my services"
- "Create a global rename plan for 'data' to 'userData'"
- Then review plans, select steps, and execute

### Monitor and Review

For operations that take time:

6. **Check progress** (Run Manager)
   - Your AI assistant monitors automatically
   - "What's the status of this refactoring?"

7. **Review and approve**
   - Use the web interface to see exact changes
   - Approve what you want, reject what you don't
