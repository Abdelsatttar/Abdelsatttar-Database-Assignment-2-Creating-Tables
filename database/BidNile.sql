/*
    BidNile Online Auctions
    Tasks 2 + 3: CREATE database/schema/tables/constraints, then ALTER changes.
    Target: SQL Server 2019+ (SSMS 20+)

    Important:
    - Exactly four schemas are created for Task 2: Reference, People, Operations, Auction.
    - No tables are created in dbo.
    - All foreign keys are added in Task 3.1, as required.
    - Specifications uses NVARCHAR(MAX) + ISJSON for SQL Server 2019+ compatibility.
    - No hand-written row-loading statements are included in this file.
*/

/* ================================================================
   TASK 2 — CREATE DATABASE AND FOUR LOGICAL SCHEMAS
   ================================================================ */

IF DB_ID(N'BidNile') IS NULL
    EXEC(N'CREATE DATABASE [BidNile]');
GO

USE [BidNile];
GO

CREATE SCHEMA [Reference];
GO
CREATE SCHEMA [People];
GO
CREATE SCHEMA [Operations];
GO
CREATE SCHEMA [Auction];
GO

/* ------------------------------
   Reference.Country
   ------------------------------ */
CREATE TABLE [Reference].[Country]
(
    [CountryCode] CHAR(2) NOT NULL,
    [NameEn] NVARCHAR(60) NOT NULL,
    [NameAr] NVARCHAR(60) NOT NULL,
    [PhoneCode] VARCHAR(8) NOT NULL,

    CONSTRAINT [PK_Country]
        PRIMARY KEY ([CountryCode]),

    CONSTRAINT [UQ_Country_NameEn]
        UNIQUE ([NameEn]),

    CONSTRAINT [CK_Country_CountryCode]
        CHECK ([CountryCode] IN ('EG', 'SA', 'AE'))
);
GO

/* ------------------------------
   Reference.City
   ------------------------------ */
CREATE TABLE [Reference].[City]
(
    [CityId] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(60) NOT NULL,
    [CountryCode] CHAR(2) NOT NULL,

    CONSTRAINT [PK_City]
        PRIMARY KEY ([CityId]),

    CONSTRAINT [UQ_City_Name_CountryCode]
        UNIQUE ([Name], [CountryCode])
);
GO

/* ------------------------------
   Reference.Category
   Category codes are assigned by the merchandising team, not generated.
   ------------------------------ */
CREATE TABLE [Reference].[Category]
(
    [CategoryId] INT NOT NULL,
    [EnglishName] NVARCHAR(50) NOT NULL,
    [ArabicName] NVARCHAR(50) NULL,
    [CommissionPercent] DECIMAL(4,2) NOT NULL,
    [ParentCategoryId] INT NULL,

    CONSTRAINT [PK_Category]
        PRIMARY KEY ([CategoryId]),

    CONSTRAINT [UQ_Category_EnglishName]
        UNIQUE ([EnglishName]),

    CONSTRAINT [CK_Category_CommissionPercent]
        CHECK ([CommissionPercent] BETWEEN 0 AND 30)
);
GO

/* ------------------------------
   People.Member
   The GUID can be supplied by the app; NEWID() is the server-side fallback.
   ------------------------------ */
CREATE TABLE [People].[Member]
(
    [MemberId] UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT [DF_Member_MemberId] DEFAULT (NEWID()),
    [FullName] NVARCHAR(100) NOT NULL,
    [Email] VARCHAR(254) NOT NULL,
    [Mobile] VARCHAR(16) NOT NULL,
    [NationalId] VARCHAR(20) NOT NULL,
    [BirthDate] DATE NOT NULL,
    [IsVerified] BIT NOT NULL
        CONSTRAINT [DF_Member_IsVerified] DEFAULT (0),
    [RegisteredAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_Member_RegisteredAt] DEFAULT (SYSUTCDATETIME()),
    [CityId] INT NOT NULL,
    [InvitedByMemberId] UNIQUEIDENTIFIER NULL,

    CONSTRAINT [PK_Member]
        PRIMARY KEY ([MemberId]),

    CONSTRAINT [UQ_Member_Email]
        UNIQUE ([Email]),

    CONSTRAINT [UQ_Member_NationalId]
        UNIQUE ([NationalId]),

    CONSTRAINT [CK_Member_MobileFormat]
        CHECK
        (
            LEN([Mobile]) BETWEEN 9 AND 16
            AND [Mobile] LIKE '+[0-9]%'
            AND SUBSTRING([Mobile], 2, 15) NOT LIKE '%[^0-9]%'
        ),

    CONSTRAINT [CK_Member_NationalId_Alphanumeric]
        CHECK (LEN([NationalId]) BETWEEN 1 AND 20 AND [NationalId] NOT LIKE '%[^A-Za-z0-9]%'),

    CONSTRAINT [CK_Member_MinimumAge]
        CHECK ([BirthDate] <= DATEADD(YEAR, -18, CONVERT(DATE, [RegisteredAt]))),

    CONSTRAINT [CK_Member_NotSelfInvited]
        CHECK ([InvitedByMemberId] IS NULL OR [InvitedByMemberId] <> [MemberId])
);
GO

/* ------------------------------
   People.Wallet
   Shared MemberId primary/foreign key enforces exactly one wallet per member.
   ------------------------------ */
CREATE TABLE [People].[Wallet]
(
    [MemberId] UNIQUEIDENTIFIER NOT NULL,
    [Balance] DECIMAL(12,2) NOT NULL
        CONSTRAINT [DF_Wallet_Balance] DEFAULT (0.00),
    [HeldAmount] DECIMAL(12,2) NOT NULL
        CONSTRAINT [DF_Wallet_HeldAmount] DEFAULT (0.00),
    [Currency] CHAR(3) NOT NULL
        CONSTRAINT [DF_Wallet_Currency] DEFAULT ('EGP'),
    [UpdatedAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_Wallet_UpdatedAt] DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_Wallet]
        PRIMARY KEY ([MemberId]),

    CONSTRAINT [CK_Wallet_Balance]
        CHECK ([Balance] >= 0),

    CONSTRAINT [CK_Wallet_HeldAmount]
        CHECK ([HeldAmount] >= 0),

    CONSTRAINT [CK_Wallet_HeldAmount_Balance]
        CHECK ([HeldAmount] <= [Balance])
);
GO

/* ------------------------------
   Operations.Warehouse
   Manager columns are nullable temporarily because Employee and Warehouse
   reference one another. Create the warehouse, then employee, then assign
   the manager. The pair check requires both manager fields together.
   ------------------------------ */
CREATE TABLE [Operations].[Warehouse]
(
    [WarehouseId] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(80) NOT NULL,
    [Capacity] INT NOT NULL,
    [CityId] INT NOT NULL,
    [Latitude] FLOAT NOT NULL,
    [Longitude] FLOAT NOT NULL,
    [ManagerMemberId] UNIQUEIDENTIFIER NULL,
    [ManagerStartDate] DATE NULL,

    CONSTRAINT [PK_Warehouse]
        PRIMARY KEY ([WarehouseId]),

    CONSTRAINT [UQ_Warehouse_Name]
        UNIQUE ([Name]),

    CONSTRAINT [CK_Warehouse_Capacity]
        CHECK ([Capacity] > 0),

    CONSTRAINT [CK_Warehouse_Latitude]
        CHECK ([Latitude] BETWEEN -90 AND 90),

    CONSTRAINT [CK_Warehouse_Longitude]
        CHECK ([Longitude] BETWEEN -180 AND 180),

    CONSTRAINT [CK_Warehouse_ManagerPair]
        CHECK
        (
            ([ManagerMemberId] IS NULL AND [ManagerStartDate] IS NULL)
            OR
            ([ManagerMemberId] IS NOT NULL AND [ManagerStartDate] IS NOT NULL)
        )
);
GO

/* ------------------------------
   People.Employee
   An employee is an existing member, so MemberId is both PK and later FK.
   ------------------------------ */
CREATE TABLE [People].[Employee]
(
    [MemberId] UNIQUEIDENTIFIER NOT NULL,
    [WarehouseId] INT NOT NULL,

    CONSTRAINT [PK_Employee]
        PRIMARY KEY ([MemberId])
);
GO

/* ------------------------------
   Operations.Item
   InspectorMemberId references Employee (an employee is also a member).
   WarehouseId stays NULL until the item arrives at a warehouse.
   ------------------------------ */
CREATE TABLE [Operations].[Item]
(
    [ItemId] INT IDENTITY(1,1) NOT NULL,
    [SellerMemberId] UNIQUEIDENTIFIER NOT NULL,
    [InspectorMemberId] UNIQUEIDENTIFIER NULL,
    [CategoryId] INT NOT NULL,
    [WarehouseId] INT NULL,
    [Title] NVARCHAR(150) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [ConditionScore] TINYINT NOT NULL
        CONSTRAINT [CK_Item_ConditionScore] CHECK ([ConditionScore] BETWEEN 1 AND 10),
    [Specifications] NVARCHAR(MAX) NOT NULL,
    [ListedAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_Item_ListedAt] DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_Item]
        PRIMARY KEY ([ItemId]),

    CONSTRAINT [CK_Item_Specifications_Json]
        CHECK (ISJSON([Specifications]) = 1),

    CONSTRAINT [CK_Item_Seller_Inspector]
        CHECK ([SellerMemberId] <> [InspectorMemberId])
);
GO

/* ------------------------------
   Operations.ItemPhoto
   Weak entity: a photo is identified by its item and its position.
   ------------------------------ */
CREATE TABLE [Operations].[ItemPhoto]
(
    [ItemId] INT NOT NULL,
    [Position] TINYINT NOT NULL,
    [Url] VARCHAR(500) NOT NULL,
    [IsMain] BIT NOT NULL
        CONSTRAINT [DF_ItemPhoto_IsMain] DEFAULT (0),

    CONSTRAINT [PK_ItemPhoto]
        PRIMARY KEY ([ItemId], [Position]),

    CONSTRAINT [CK_ItemPhoto_Position]
        CHECK ([Position] BETWEEN 1 AND 20)
);
GO

/* ------------------------------
   Auction.Auction
   ------------------------------ */
CREATE TABLE [Auction].[Auction]
(
    [AuctionId] INT IDENTITY(1,1) NOT NULL,
    [ItemId] INT NOT NULL,
    [StartingPrice] DECIMAL(12,2) NOT NULL,
    [ReservePrice] DECIMAL(12,2) NULL,
    [BidIncrement] DECIMAL(12,2) NOT NULL
        CONSTRAINT [DF_Auction_BidIncrement] DEFAULT (50.00),
    [StartAt] DATETIMEOFFSET(3) NOT NULL,
    [EndAt] DATETIMEOFFSET(3) NOT NULL,
    [Status] VARCHAR(20) NOT NULL
        CONSTRAINT [DF_Auction_Status] DEFAULT ('Draft'),

    CONSTRAINT [PK_Auction]
        PRIMARY KEY ([AuctionId]),

    CONSTRAINT [CK_Auction_StartingPrice]
        CHECK ([StartingPrice] > 0),

    CONSTRAINT [CK_Auction_ReservePrice]
        CHECK ([ReservePrice] IS NULL OR [ReservePrice] >= [StartingPrice]),

    CONSTRAINT [CK_Auction_BidIncrement]
        CHECK ([BidIncrement] > 0),

    CONSTRAINT [CK_Auction_TimeRange]
        CHECK ([EndAt] > [StartAt]),

    CONSTRAINT [CK_Auction_Status]
        CHECK ([Status] IN ('Draft', 'Live', 'Ended', 'Cancelled'))
);
GO

/* ------------------------------
   Auction.Bid
   BIGINT IDENTITY supports the expected counter beyond 2.1 billion.
   IpAddress is renamed to DeviceIp in Task 3.4.
   ------------------------------ */
CREATE TABLE [Auction].[Bid]
(
    [BidId] BIGINT IDENTITY(1,1) NOT NULL,
    [AuctionId] INT NOT NULL,
    [MemberId] UNIQUEIDENTIFIER NOT NULL,
    [Amount] DECIMAL(12,2) NOT NULL,
    [PlacedAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_Bid_PlacedAt] DEFAULT (SYSUTCDATETIME()),
    [IpAddress] VARCHAR(45) NOT NULL,

    CONSTRAINT [PK_Bid]
        PRIMARY KEY ([BidId]),

    CONSTRAINT [UQ_Bid_Auction_Amount]
        UNIQUE ([AuctionId], [Amount]),

    CONSTRAINT [CK_Bid_Amount]
        CHECK ([Amount] > 0)
);
GO

/* ------------------------------
   Auction.AuctionFollower
   Composite PK prevents one member following the same auction twice.
   This table is moved to Marketing in Task 3.12.
   ------------------------------ */
CREATE TABLE [Auction].[AuctionFollower]
(
    [AuctionId] INT NOT NULL,
    [MemberId] UNIQUEIDENTIFIER NOT NULL,
    [FollowedAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_AuctionFollower_FollowedAt] DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT [PK_AuctionFollower]
        PRIMARY KEY ([AuctionId], [MemberId])
);
GO

/*
    A filtered unique index is used instead of a UNIQUE constraint for the
    optional manager. It permits many warehouses to have NULL temporarily,
    while ensuring that a non-NULL employee manages at most one warehouse.
*/
CREATE UNIQUE INDEX [UQ_Warehouse_ManagerMemberId]
    ON [Operations].[Warehouse] ([ManagerMemberId])
    WHERE [ManagerMemberId] IS NOT NULL;
GO

/* ================================================================
   TASK 3 — ALTER THE EXISTING DESIGN
   ================================================================ */

/* 3.1 — Connect everything. Foreign keys are added only here. */

-- 3.1
ALTER TABLE [Reference].[City]
    ADD CONSTRAINT [FK_City_Country]
    FOREIGN KEY ([CountryCode]) REFERENCES [Reference].[Country] ([CountryCode]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [People].[Member]
    ADD CONSTRAINT [FK_Member_City]
    FOREIGN KEY ([CityId]) REFERENCES [Reference].[City] ([CityId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [People].[Member]
    ADD CONSTRAINT [FK_Member_InvitedByMember]
    FOREIGN KEY ([InvitedByMemberId]) REFERENCES [People].[Member] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [People].[Wallet]
    ADD CONSTRAINT [FK_Wallet_Member]
    FOREIGN KEY ([MemberId]) REFERENCES [People].[Member] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Operations].[Warehouse]
    ADD CONSTRAINT [FK_Warehouse_City]
    FOREIGN KEY ([CityId]) REFERENCES [Reference].[City] ([CityId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [People].[Employee]
    ADD CONSTRAINT [FK_Employee_Member]
    FOREIGN KEY ([MemberId]) REFERENCES [People].[Member] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [People].[Employee]
    ADD CONSTRAINT [FK_Employee_Warehouse]
    FOREIGN KEY ([WarehouseId]) REFERENCES [Operations].[Warehouse] ([WarehouseId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Operations].[Warehouse]
    ADD CONSTRAINT [FK_Warehouse_ManagerEmployee]
    FOREIGN KEY ([ManagerMemberId]) REFERENCES [People].[Employee] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Reference].[Category]
    ADD CONSTRAINT [FK_Category_ParentCategory]
    FOREIGN KEY ([ParentCategoryId]) REFERENCES [Reference].[Category] ([CategoryId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Operations].[Item]
    ADD CONSTRAINT [FK_Item_SellerMember]
    FOREIGN KEY ([SellerMemberId]) REFERENCES [People].[Member] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Operations].[Item]
    ADD CONSTRAINT [FK_Item_InspectorEmployee]
    FOREIGN KEY ([InspectorMemberId]) REFERENCES [People].[Employee] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Operations].[Item]
    ADD CONSTRAINT [FK_Item_Category]
    FOREIGN KEY ([CategoryId]) REFERENCES [Reference].[Category] ([CategoryId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Operations].[Item]
    ADD CONSTRAINT [FK_Item_Warehouse]
    FOREIGN KEY ([WarehouseId]) REFERENCES [Operations].[Warehouse] ([WarehouseId]) ON DELETE NO ACTION;
GO

-- 3.1 — Deleting an item deletes its photos; no other FK cascades.
ALTER TABLE [Operations].[ItemPhoto]
    ADD CONSTRAINT [FK_ItemPhoto_Item]
    FOREIGN KEY ([ItemId]) REFERENCES [Operations].[Item] ([ItemId])
    ON DELETE CASCADE;
GO

-- 3.1
ALTER TABLE [Auction].[Auction]
    ADD CONSTRAINT [FK_Auction_Item]
    FOREIGN KEY ([ItemId]) REFERENCES [Operations].[Item] ([ItemId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Auction].[Bid]
    ADD CONSTRAINT [FK_Bid_Auction]
    FOREIGN KEY ([AuctionId]) REFERENCES [Auction].[Auction] ([AuctionId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Auction].[Bid]
    ADD CONSTRAINT [FK_Bid_Member]
    FOREIGN KEY ([MemberId]) REFERENCES [People].[Member] ([MemberId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Auction].[AuctionFollower]
    ADD CONSTRAINT [FK_AuctionFollower_Auction]
    FOREIGN KEY ([AuctionId]) REFERENCES [Auction].[Auction] ([AuctionId]) ON DELETE NO ACTION;
GO

-- 3.1
ALTER TABLE [Auction].[AuctionFollower]
    ADD CONSTRAINT [FK_AuctionFollower_Member]
    FOREIGN KEY ([MemberId]) REFERENCES [People].[Member] ([MemberId]) ON DELETE NO ACTION;
GO

/* 3.2 — Add app language; NOT NULL plus DEFAULT populates existing rows with 'ar'. */
-- 3.2
ALTER TABLE [People].[Member]
    ADD [AppLanguage] VARCHAR(2) NOT NULL
        CONSTRAINT [DF_Member_AppLanguage] DEFAULT ('ar'),
        CONSTRAINT [CK_Member_AppLanguage]
            CHECK ([AppLanguage] IN ('ar', 'en'));
GO

/* 3.3 — New items are not featured by default. */
-- 3.3
ALTER TABLE [Operations].[Item]
    ADD [Featured] BIT NOT NULL
        CONSTRAINT [DF_Item_Featured] DEFAULT (0)
        WITH VALUES;
GO

/* 3.4 — Rename columns with sp_rename (not ALTER TABLE). */
-- 3.4
EXEC sys.sp_rename
    @objname = N'Auction.Bid.IpAddress',
    @newname = N'DeviceIp',
    @objtype = N'COLUMN';
GO

-- 3.4
EXEC sys.sp_rename
    @objname = N'Operations.Warehouse.Capacity',
    @newname = N'MaxItems',
    @objtype = N'COLUMN';
GO

/* 3.5 — Widen FullName and explicitly preserve NOT NULL. */
-- 3.5
ALTER TABLE [People].[Member]
    ALTER COLUMN [FullName] NVARCHAR(150) NOT NULL;
GO

/* 3.6 — SMALLINT is the smallest SQL Server integer type that holds 30,000.
   The original CHECK depends on the column, so drop it before narrowing the
   type, then recreate the same > 0 rule under the renamed column's name.
   A direct ALTER COLUMN before dropping the CHECK is the expected failure.
*/
-- 3.6
ALTER TABLE [Operations].[Warehouse]
    DROP CONSTRAINT [CK_Warehouse_Capacity];
GO

-- 3.6
ALTER TABLE [Operations].[Warehouse]
    ALTER COLUMN [MaxItems] SMALLINT NOT NULL;
GO

-- 3.6
ALTER TABLE [Operations].[Warehouse]
    ADD CONSTRAINT [CK_Warehouse_MaxItems] CHECK ([MaxItems] > 0);
GO

/* 3.7 — Replace the maximum commission rule: 30 becomes 25. */
-- 3.7
ALTER TABLE [Reference].[Category]
    DROP CONSTRAINT [CK_Category_CommissionPercent];
GO

-- 3.7
ALTER TABLE [Reference].[Category]
    ADD CONSTRAINT [CK_Category_CommissionPercent]
    CHECK ([CommissionPercent] BETWEEN 0 AND 25);
GO

/* 3.8 — PendingReview becomes an allowed status and the new default. */
-- 3.8
ALTER TABLE [Auction].[Auction]
    DROP CONSTRAINT [CK_Auction_Status];
GO

-- 3.8
ALTER TABLE [Auction].[Auction]
    DROP CONSTRAINT [DF_Auction_Status];
GO

-- 3.8
ALTER TABLE [Auction].[Auction]
    ADD CONSTRAINT [CK_Auction_Status]
    CHECK ([Status] IN ('Draft', 'PendingReview', 'Live', 'Ended', 'Cancelled'));
GO

-- 3.8
ALTER TABLE [Auction].[Auction]
    ADD CONSTRAINT [DF_Auction_Status] DEFAULT ('PendingReview') FOR [Status];
GO

/* 3.9 — BuyNowPrice is optional. WITH CHECK validates current rows; NULLs
   already present in this new optional column satisfy the condition.
*/
-- 3.9
ALTER TABLE [Auction].[Auction]
    ADD [BuyNowPrice] DECIMAL(12,2) NULL;
GO

-- 3.9
ALTER TABLE [Auction].[Auction] WITH CHECK
    ADD CONSTRAINT [CK_Auction_BuyNowPrice]
    CHECK ([BuyNowPrice] IS NULL OR [BuyNowPrice] > [StartingPrice]);
GO

/* 3.10 — Mobile numbers must now be unique. */
-- 3.10
ALTER TABLE [People].[Member]
    ADD CONSTRAINT [UQ_Member_Mobile] UNIQUE ([Mobile]);
GO

/* 3.11 — Add optional verification timestamp, then remove the old flag.
   Drop its named DEFAULT first because the default is attached to IsVerified.
*/
-- 3.11
ALTER TABLE [People].[Member]
    ADD [VerifiedAt] DATETIME2(3) NULL;
GO

-- 3.11
ALTER TABLE [People].[Member]
    DROP CONSTRAINT [DF_Member_IsVerified];
GO

-- 3.11
ALTER TABLE [People].[Member]
    DROP COLUMN [IsVerified];
GO

/* 3.12 — Marketing takes ownership of the engagement/follow table. */
CREATE SCHEMA [Marketing];
GO

-- 3.12
ALTER SCHEMA [Marketing] TRANSFER [Auction].[AuctionFollower];
GO

/* ================================================================
   END OF TASKS 2 + 3
   ================================================================ */
