use Efrat_Yanay_project_Bank
--1
create function last_balance (@ownwer_id int) returns money
as
begin
declare @balance money
select top 1 @balance=  [balance] from dbo.movements where [oenerId]=@ownwer_id order by [moveDate] desc
return @balance
end

create view daily_summary
as
select a1.ownerId,a1.fullname as name_cust, a1.tz,convert(date, m1.moveDate) as date,sum(iif(m1.sumAcount>0,m1.sumAcount,0)) as credit,sum(iif(m1.sumAcount<0,m1.sumAcount,0)) as charge , dbo.last_balance (a1.ownerId) as balance,iif(dbo.last_balance(a1.ownerId) <-a1.accountLimit,'yes','no') as is_over
from dbo.accounts a1 join dbo.movements m1 on a1.ownerId=m1.oenerId 
group by convert(date, m1.moveDate),  a1.ownerId,a1.fullname , a1.tz, dbo.last_balance (a1.ownerId),iif(dbo.last_balance(a1.ownerId) <-a1.accountLimit,'yes','no') 
select * from daily_summary
--2
create procedure select_details
as
select m.moveId,a.fullname,a.accountNum,a.snifNum,m.sumAcount,m.description,m.balance
from dbo.movements m join dbo.accounts a on a.ownerId=m.oenerId

exec select_details
--3
go
create procedure add_movement @ownerid int ,@desc varchar(50),@sum money,@balance money
as
if(@ownerid not in (select [ownerId] from [dbo].[accounts]))
	RAISERROR('מספר חשבון לא קיים',16,1)
else
	insert dbo.movements values(getdate(),@ownerid,@desc,@sum,@balance)
exec add_movement 100,'הפקדת מזומן',400,61300
--4
go
create procedure update_movement @moveid int,@sum money
as
update dbo.movements set sumAcount=@sum from dbo.movements
where moveId=@moveid and (month(moveDate)=month(getdate()) and year(moveDate)=year(getdate()) and (day(moveDate)=day(getdate()) or (datename(weekday,getdate())='monday' and (datename(weekday,moveDate)='sunday')or datename(weekday,moveDate)='saturday') ) )

--5
create table history_movements(
moveId int,
moveDate datetime,
oenerId int,
description varchar(20),
sumAcount money,
balance money
)
go
create procedure delete_movement @moveid int
as
insert into dbo.history_movements select * from dbo.movements where moveId=@moveid
delete from dbo.movements where moveId=@moveid
--6
go
create function out_of_limit (@date_over datetime ,@ownerid int) returns int
as
begin
declare @balance money,@limit_sum money,@sum_over money,@count_days int
select @balance = balance from dbo.movements where oenerId=@ownerid and moveDate=@date_over
select @limit_sum =a.accountLimit from dbo.movements m  join dbo.accounts a   on a.ownerId=m.oenerId where m.oenerId=@ownerid
set @sum_over=@balance+@limit_sum
;with temp_tbl as(
	select moveDate 
	from dbo.movements 
	where oenerId=@ownerid 
	and moveDate>@date_over 
	and balance+@sum_over>=0
)
select  @count_days= datediff(day,@date_over,min(movedate)) from temp_tbl
return @count_days
end
--7!
go
create function is_allowed (@moveid int) returns varchar(20)
as
begin
declare @balance int, @limit int,@ownerid int
declare @date_over date
select @ownerid=oenerId from dbo.movements
select @limit= a.accountLimit from dbo.movements m join dbo.accounts a on m.oenerId=a.ownerId and m.moveId=@moveid
select @balance=balance from dbo.movements
select @date_over=moveDate from dbo.movements m join dbo.accounts a on a.ownerId=m.oenerId and m.moveId=@moveid where m.balance<a.accountLimit*(-1)
if((@balance>=(@limit)*(-1))
	return 'מורשה'
if((@balance>=(@limit+1000)*(-1)) and(out_of_limit(@dat_over,@moveid)<=7)))
	return 'מורשה'
return 'לא מורשה'


end
--8!
go
create trigger trig_insert on [dbo].[movements] for insert
as
begin
	declare @prev_balance money,@sum money
	declare @ownerid int

	if update(sumAccount)
		begin
			;with cte
			as (
			select top 2 * from dbo.movements order by [moveDate] desc
			)

			select @ownerid= [oenerId] from inserted
			select @sum=[sumAcount] from inserted
			select top 1 @prev_balance = [balance] from cte where [oenerId]=@ownerid order by [moveDate]
			update dbo.movements
			set balance = @prev_balance+@sum
			where [moveId] = select top 1 [moveId] from cte
		end
end
--9
create function func9 (@date datetime,@num_days int) returns @t1 table( credit money,charges money,balance money)
as
begin
insert into @t1 
select [credit],[charge],[balance]
from daily_summary
where [date]>=@date and [date]<dateadd(day,@num_days,@date)
return
end
select * from func9('1900-01-01',5)


--10
--a
---בהצלחה














