USE PROMBD
GO
 
create table [dbo].[disp_dic_work_hours] ([date_d] date NULL, [time_start] time(7) NULL, [time_end] time(7) NULL, [work_hours] float NULL, [date_start] datetime NULL, [date_end] datetime NULL)
GO
 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
create FUNCTION  [dbo].[f_clear_time]
(
      
       @start_time datetime,
       @end_time datetime
)
RETURNS float
AS
BEGIN
      
       DECLARE @clear_time float

       select @clear_time=round((min_total_days-min_to_end-min_from_start)/60,2)  from (

       select
       case
             when work_hours1=0 then 0
             else datediff(mi,date_start1,hold_start_corr)
       end as min_from_start,
 
       case
             when work_hours1=0 then 0
             else datediff(mi,hold_end_corr,date_end2)
       end as min_to_end,

       (select sum(work_hours) as work_hours_total from
       (select * from [dbo].[disp_dic_work_hours] q21

       where ((datepart(yy,date_d)>datepart(yy,(SELECT @start_time AS hold_start)))  or
       (datepart(yy,date_d)=datepart(yy,(SELECT @start_time AS hold_start)) and datepart(m,date_d)>datepart(m,(SELECT @start_time AS hold_start))) or
       (datepart(yy,date_d)=datepart(yy,(SELECT @start_time AS hold_start)) and datepart(m,date_d)=datepart(m,(SELECT @start_time AS hold_start)) and datepart(d,date_d)>=datepart(d,(SELECT @start_time AS hold_start)))) and
       ((datepart(yy,date_d)<datepart(yy,(SELECT  @end_time AS hold_end)))  or
       (datepart(yy,date_d)=datepart(yy,(SELECT  @end_time AS hold_end)) and datepart(m,date_d)<datepart(m,(SELECT  @end_time AS hold_end))) or
       (datepart(yy,date_d)=datepart(yy,(SELECT  @end_time AS hold_end)) and datepart(m,date_d)=datepart(m,(SELECT  @end_time AS hold_end)) and datepart(d,date_d)<=datepart(d,(SELECT  @end_time AS hold_end))))) ww1)*60 as min_total_days,

       * from
 
       (SELECT
 
       /****** скоректированное время старта  ******/
       case
             when q1.hold_start<q21.date_start then q21.date_start
             when q1.hold_start>q21.date_end then q21.date_end
             else q1.hold_start
       end as hold_start_corr,
 
       /****** скоректированное время окончания  ******/
       case
             when q1.hold_end<q22.date_start then q22.date_start
             when q1.hold_end>q22.date_end then q22.date_end
             else q1.hold_end
       end as hold_end_corr,
 
       q1.hold_start, q1.hold_end,
       q21.date_start as date_start1, q21.date_end as date_end1, q21.work_hours as work_hours1,
       q22.date_start as date_start2, q22.date_end as date_end2, q22.work_hours as work_hours2
	   
         FROM (SELECT @start_time AS hold_start, @end_time AS hold_end) q1
         inner join [dbo].[disp_dic_work_hours] q21
         on datepart(d,q1.hold_start)=datepart(d,q21.date_d) and datepart(m,q1.hold_start)=datepart(m,q21.date_d) and datepart(yy,q1.hold_start)=datepart(yy,q21.date_d)
         inner join [dbo].[disp_dic_work_hours] q22
         on datepart(d,q1.hold_end)=datepart(d,q22.date_d) and datepart(m,q1.hold_end)=datepart(m,q22.date_d) and datepart(yy,q1.hold_end)=datepart(yy,q22.date_d)) qq1) qq2;
      
 
      
       RETURN @clear_time
 
END