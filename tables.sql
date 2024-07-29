create database Efrat_Yanay_project_Bank
--יצירת טבלת סניפים
create table snifim(
snifId int primary key,
snifNum int,
snifName varchar(20)
)
--יצירת טבלת חשבונות
create table accounts(
ownerId int identity primary key,
firstName varchar(20),
lastName varchar(20),
fullname as firstName+' '+lastName,
tz varchar(9),
tel varchar(10),
accountNum int,
snifNum int foreign key (snifNum) references dbo.snifim(snifId),
accountType varchar(4) check (accountType in('פרטי','עסקי')),
accountLimit int
)
--יצירת טבלת תנועות
create table movements(
moveId int primary key identity,
moveDate datetime,
oenerId int foreign key(oenerId) references dbo.accounts(ownerId),
description varchar(20),
sumAcount money,
balance money
)