# NOTES.md — Section 03

## 1. Four schemas and why

- **Reference** — `Country`, `City`, and `Category`. These are shared lookup/catalogue structures used by the rest of the system.
- **People** — `Member`, `Wallet`, and `Employee`. These describe account holders and the one-to-one wallet / employee extensions of a member.
- **Operations** — `Warehouse`, `Item`, and `ItemPhoto`. These describe the physical and merchandising workflow for inventory.
- **Auction** — `Auction`, `Bid`, and initially `AuctionFollower`. Task 3.12 moves `AuctionFollower` into the new `Marketing` schema because engagement data becomes Marketing-owned. Therefore the final database has the four original schemas plus `Marketing` after Task 3.12.

## 2. Relationship types and how they are mapped

- **1:1 — Member to Wallet:** `Wallet.MemberId` is both the primary key and a foreign key to `Member.MemberId`. The shared key prevents two wallets for one member and prevents a wallet without a member.
- **1:1 — Member to Employee:** `Employee.MemberId` is both its primary key and a foreign key to `Member.MemberId`. Employee is a subtype/extension of Member; not every member is an employee.
- **1:1 — Warehouse manager assignment:** `Warehouse.ManagerMemberId` optionally references `Employee.MemberId`. A filtered unique index allows many unassigned warehouses during initial loading but ensures one employee cannot manage multiple warehouses. `ManagerStartDate` is stored with the assignment.
- **1:N — City to Member / Warehouse:** `Member.CityId` and `Warehouse.CityId` reference `City.CityId`.
- **1:N — Warehouse to Employee / Item:** `Employee.WarehouseId` and optional `Item.WarehouseId` reference `Warehouse.WarehouseId`.
- **1:N — Member to Items as seller:** `Item.SellerMemberId` references `Member.MemberId`.
- **1:N — Employee to Items as inspector:** optional `Item.InspectorMemberId` references `Employee.MemberId`; an employee is also a member.
- **1:N — Category to Item and Category to child Category:** `Item.CategoryId` references `Category.CategoryId`; `Category.ParentCategoryId` is a self-reference.
- **1:N — Item to Auction:** `Auction.ItemId` references `Item.ItemId`. ItemId is not unique in Auction, so an item may be auctioned again.
- **1:N — Auction to Bid:** `Bid.AuctionId` references `Auction.AuctionId`.
- **M:N — Member to Auction through bids:** `Bid` is the associative entity and stores the bid attributes. The same member can bid multiple times in the same auction.
- **M:N — Member to Auction through follows:** `AuctionFollower` is the associative entity with composite primary key `(AuctionId, MemberId)`, preventing duplicate follows.
- **Recursive — Member referrals:** `Member.InvitedByMemberId` references `Member.MemberId`.
- **Recursive — Category hierarchy:** `Category.ParentCategoryId` references `Category.CategoryId`.
- **Circular — Employee and Warehouse:** `Employee.WarehouseId` references `Warehouse`, while `Warehouse.ManagerMemberId` references `Employee`. The manager columns are nullable until the employee rows have been loaded; managers are then assigned.
- **Weak entity — ItemPhoto:** the composite key `(ItemId, Position)` identifies each photo only within its owning item. The FK uses `ON DELETE CASCADE`, so deleting an item deletes its photos.

## 3. Data type choices

- **GUID for Member:** mobile clients can create globally unique identifiers before contacting the server, so the ID is not dependent on a central running counter. `NEWID()` is the server-side default if the client omits it.
- **BIGINT for Bid:** the brief expects the bid counter to exceed 2.1 billion; `INT` cannot represent values above 2,147,483,647 reliably for that long-term growth target.
- **FLOAT for GPS:** latitude and longitude are approximate measurements with many decimal places, not currency values requiring exact arithmetic.
- **DECIMAL for money:** balances, holds, prices, bids, increments, and commission percentages need exact decimal arithmetic; floating-point rounding is not suitable.
- **DATETIMEOFFSET for auctions:** auction start/end values must preserve the local time-zone offset for Cairo, Riyadh, and Dubai.
- **DATETIME2(3):** used for timestamps that require millisecond precision but do not need an offset in the business description.
- **NVARCHAR:** names and titles can contain Arabic or English text. `VARCHAR` is used for Latin-only email, mobile, national ID, IP, and URL values.
- **NVARCHAR(MAX) + ISJSON:** stores one valid JSON document per item while remaining compatible with SQL Server 2019+.

## 4. Why the circular relationship cannot be created entirely inside the first CREATE TABLE

`Employee` needs `WarehouseId`, while `Warehouse` needs `ManagerMemberId` pointing to an employee. When one table is being created, the other table may not exist yet. The script therefore creates both tables and their FK columns first, then adds the cross-table FK constraints with `ALTER TABLE` in Task 3.1. The manager columns can be NULL during initial import and are filled after employees exist.

## 5. Task 4 data-loading order and why

1. `Country` before `City`, because each city references a country.
2. `City` and `Category` before dependent rows; category parents are imported before child categories.
3. `Member` before `Wallet`, `Employee`, `Item`, `Bid`, and followers. Referral inviters appear before invitees in the sheet.
4. `Wallet` after members because it has a shared PK/FK.
5. `Warehouse` before `Employee`, because each employee must work in an existing warehouse. Manager fields are initially NULL.
6. `Employee` after warehouses, then update each warehouse's manager ID and manager start date. This order resolves the circular relationship without disabling FKs.
7. `Item` after members, employees, categories, and warehouses.
8. `ItemPhoto` after items; then `Auction` after items; then `Bid` and `AuctionFollower` after auctions and members.

The provided workbook contains 10 members, 40 bids, all five post-Task-3 auction statuses, multiple time-zone offsets, referrals, a member who both sells and bids, and valid JSON documents with different keys for Cars and Mobiles. The Country table has three rows because the business description names three current operating countries (EG, SA, AE); no additional operating market was invented.

## 6. Expected errors in 3.6 and 3.11 and their fixes

- **3.6 — Narrowing MaxItems:** changing the column type while `CK_Warehouse_Capacity` still depends on the column causes SQL Server to reject the ALTER. The script drops that check constraint, changes the renamed column to `SMALLINT`, then recreates the positive-value rule as `CK_Warehouse_MaxItems`.
- **3.11 — Dropping IsVerified:** the column has the named default constraint `DF_Member_IsVerified` attached. SQL Server will not drop the column while that dependency exists. The script first adds nullable `VerifiedAt`, drops the default constraint by name, and then drops `IsVerified`.

## 7. Hand trace for [1, 2, 3, 4]

`prefix[i]` is the product of all values to the left of index i; `suffix[i]` is the product of all values to the right.

| Index | Input | Prefix (left product) | Suffix (right product) | Output |
|---:|---:|---:|---:|---:|
| 0 | 1 | 1 | 24 | 24 |
| 1 | 2 | 1 | 12 | 12 |
| 2 | 3 | 2 | 4 | 8 |
| 3 | 4 | 6 | 1 | 6 |

Result: `[24, 12, 8, 6]`.
