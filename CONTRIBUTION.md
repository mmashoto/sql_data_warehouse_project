# Contribution Guidelines

## Introduction

This document outlines the standards, workflow, and expectations for contributing to this SQL‑driven data warehouse project. Its purpose is to maintain clarity, architectural consistency, and technical accuracy across all contributions.

Contributors are encouraged to read this entire guideline before submitting any changes to ensure alignment with established engineering practices.

## Contribution Workflow

Below is the complete contribution process, presented with precision, practicality, and the occasional warning from the ghosts of failed ETL pipelines.

2.1 Fork the Repository
Duplicate the repository under your own GitHub profile.

```git
git clone https://github.com/<your-username>/<repository-name>
git cd <repository-name> 
```

2.2 Create a Feature Branch

All changes must occur in a dedicated feature branch.

```git
git checkout -b feature/improve-scd-handling 
```

Branch names must be descriptive and purposeful.

2.3 Implement Changes and Add Tests

Your contribution must meet the following expectations:
• Align with warehouse architecture (STG, DWH, DM).
• Include SQL tests or validation queries.
• Maintain design clarity and performance efficiency.
• Improve, not complicate, the flow of data.
Commit using the conventional message structure:

```git
git add . git commit -m "feat: introduce incremental SCD2 logic for dim_customer" 

```

Valid types include: feat, fix, docs, refactor, test, chore.

2.4 Run Data Quality Checks

All contributions must satisfy the following integrity standards:

- No broken joins or orphaned records.
- No accidental cross joins.
- No SELECT * in production logic.
- SQL keywords uppercase; identifiers snake_case.
- Incremental loads must be idempotent.
- Grain must match the intended fact or dimension.
- Query plans must be reasonable (no table scans that melt dashboards).

2.5 Submit a Pull Request

Push your branch:
git push origin feature/improve-scd-handling 

Open a pull request using:

- Base branch: main
- Compare: your feature branch

Your PR description must include:

- Summary of the change
- Justification for the change
- Impact on warehouse logic
- Testing performed

Pull requests without meaningful context will not be accepted.

## Contribution Etiquette

To maintain consistency and quality throughout the project, contributors must adhere to the following principles:

- Use alphabetical order when adding items to lists.
- Verify spelling and grammar.
- Keep changes focused; one PR per concern.
- Document logic, assumptions, and impacts.
- Follow established naming conventions.
- Ensure meaningful PR and commit titles.
- Avoid bypassing review processes.

## Advanced Engineering Standards

This project reflects disciplined data engineering. Contributions should align with the expectations below.

### SQL Style Guide

- Uppercase reserved keywords.
- Use snake_case for table and column names.
- Never rely on implicit joins.
- Avoid ambiguous logic or mysterious expressions.
- Store data in correct types.
- Apply consistent surrogate key strategies.

### Performance Guidelines

-  Review execution plans.
-  Index with intention.
- Partition strategically.
- Avoid unnecessary full-table operations.
- Keep ETL processes modular and efficient.
- Respect memory and compute boundaries.

### Data Modeling Expectations

- Validate grain before finalizing facts.
- Maintain integrity across dimensions.
- Ensure relationships remain understandable and traceable.
- Prevent circular dependencies.
- Preserve warehouse layer boundaries.

## Issues and Suggestions

- Clear reproduction steps
- Screenshots or logs (if applicable)
- Expected vs actual behavior
- Potential solutions
Issues lacking detail may delay resolution.

## Final Appreciation

Your contributions strengthen the warehouse, sharpen the architecture, and support the long-term evolution of this project. Thank you for offering your time, expertise, and insight.