# BidNile — Database Design & SQL Server DDL

**Student:** Ahmed Mohamed Abdel Sattar  
**Group:** [Fill in your Simulation Academy group]  
**ID:** [Fill in your Simulation Academy ID]

## Submission structure

```text
BidNile/
├── docs/
│   ├── mapping.png                 (Task 1)
│   ├── mapping.svg                 (editable Task 1 copy)
│   ├── erd.png                     (optional +5 bonus)
│   ├── erd.svg                     (editable bonus copy)
│   └── screenshots/                (real screenshots to add)
├── database/
│   ├── BidNile.sql                 (Tasks 2 + 3)
│   ├── BidNile_Data.sql             (replace placeholder with SSMS Data-only export)
│   ├── BidNile_ImportData.xlsx      (Task 4 source workbook for SSMS Wizard)
│   └── Task4_Import_Guide.md
├── dsa/
│   └── ProductExceptSelf.cs        (Task 5 C# code only)
├── NOTES.md                        (Section 03 answers and hand trace)
└── README.md
```

## SQL setup

1. Use SQL Server 2019+ with SSMS 20+.
2. Open `database/BidNile.sql` in SSMS.
3. Run the complete file with **F5** on a fresh SQL Server instance.
4. The script creates the four original Task 2 schemas and applies all Task 3 changes, including the `Marketing` schema transfer in 3.12.

## Task 4

Use `database/BidNile_ImportData.xlsx` with the SSMS Import and Export Wizard. Follow `database/Task4_Import_Guide.md` for the required order and identity / manager notes. The current `BidNile_Data.sql` is intentionally comment-only until SSMS generates the Data-only export after import. Replace it with that SSMS-generated file before final submission.

Add the three Task 4 constraint-error screenshots and the LeetCode Accepted screenshot to `docs/screenshots/`. The folder's README gives the exact filenames and what each screenshot should show; no screenshots have been fabricated.

## Task 5

`dsa/ProductExceptSelf.cs` contains both requested approaches in LeetCode C# `Solution` format: the prefix/suffix-array implementation and the O(1) extra-space follow-up. `NOTES.md` includes the manual trace for `[1, 2, 3, 4]`.

## Before opening the Pull Request

- Fill in Group and ID above.
- Replace the Task 4 data-export placeholder with the actual SSMS Data-only export.
- Add the four real screenshots.
- Use the exact branch name and Pull Request title shown on the Simulation Academy website. Do not commit directly to `main`.
