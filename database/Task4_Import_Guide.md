# Task 4 — SSMS Wizard Import Guide

## Before importing

1. Open `BidNile.sql` in SSMS 20+ connected to SQL Server 2019 or later.
2. Run the complete script with **F5** on a fresh instance. It creates the database and applies Tasks 2 and 3.
3. Open **SQL Server Import and Export Wizard** and choose `BidNile_ImportData.xlsx` as the source. Use the first row as column names.
4. Choose the SQL Server destination and the `BidNile` database. Map each worksheet to the two-part destination table shown below. Keep identity generation enabled by leaving identity columns unmapped; do not supply identity values.

## Import order

| Order | Worksheet | Destination table |
|---:|---|---|
| 1 | Country | `Reference.Country` |
| 2 | City | `Reference.City` |
| 3 | Category | `Reference.Category` |
| 4 | Member | `People.Member` |
| 5 | Wallet | `People.Wallet` |
| 6 | Warehouse | `Operations.Warehouse` |
| 7 | Employee | `People.Employee` |
| 8 | Item | `Operations.Item` |
| 9 | ItemPhoto | `Operations.ItemPhoto` |
| 10 | Auction | `Auction.Auction` |
| 11 | Bid | `Auction.Bid` |
| 12 | AuctionFollower | `Marketing.AuctionFollower` |

## Important mapping notes

- Import into a **fresh, empty** `BidNile` database. The workbook omits the identity columns so SQL Server generates the IDs.
- The worksheet references assume the five City, Warehouse, Item, and Auction rows receive IDs 1 through 5 in worksheet order.
- `Warehouse.ManagerMemberId` and `Warehouse.ManagerStartDate` are initially blank to resolve the circular Warehouse/Employee relationship. After importing `Employee`, open `Operations.Warehouse` with **Edit Top 200 Rows** and set each warehouse's manager to an employee who works there, including the start date.
- The member rows include the post-Task-3 columns `AppLanguage` and `VerifiedAt`; the old `IsVerified` column is no longer present after Task 3.11.
- `AuctionFollower` is imported into `Marketing.AuctionFollower`, because Task 3.12 moves it from `Auction`.
- The business description names only EG, SA, and AE. Therefore the `Country` lookup has three legitimate rows; the other tables have at least five rows, including 10 members and 40 bids.
- The auction start/end cells include explicit offsets. Confirm that the wizard maps them to `datetimeoffset(3)` without losing the `+02:00`, `+03:00`, and `+04:00` offsets.

## Create `BidNile_Data.sql`

After the import succeeds, use **Tasks → Generate Scripts** in SSMS. Select the required tables, open **Advanced**, set **Types of data to script** to **Data only**, and save the generated output as `database/BidNile_Data.sql`, replacing the comment-only placeholder. Keep the generated output from SSMS; do not hand-author it.

## Required Task 4 error screenshots

See `docs/screenshots/README.md` for the three constraint-error screenshots to capture after the valid data has loaded.
