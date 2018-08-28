-- select DB you want to use
use PROMBD
go

 -- off information messages
SET NOCOUNT ON

-- delete all tables and schemes that allready exists
if object_ID('sgd.predict') is not null drop function sgd.predict
if object_ID('sgd.update_w') is not null drop function sgd.update_w
if object_ID('sgd.input_x') is not null drop table sgd.input_x
if object_ID('sgd.y_true') is not null drop table sgd.y_true
if object_ID('sgd.coeff') is not null drop table sgd.coeff
if object_ID('sgd.coeff_learning') is not null drop table sgd.coeff_learning
if object_ID('sgd.error_learning') is not null drop table sgd.error_learning
if schema_ID('sgd') is not null drop schema sgd
go
 
-- create scheme for the algoritm
create schema sgd;
go
      
-- create table for input X values
create table sgd.input_x ([x_value] float NULL, [x_example] int NULL, [x_num] int NULL)
go
 
-- input test X values
insert into sgd.input_x (x_value, x_example, x_num) values (0.1, 1, 1)
insert into sgd.input_x (x_value, x_example, x_num) values (0.3, 2, 1)
insert into sgd.input_x (x_value, x_example, x_num) values (0.5, 3, 1)
insert into sgd.input_x (x_value, x_example, x_num) values (0.7, 4, 1)
insert into sgd.input_x (x_value, x_example, x_num) values (0.9, 5, 1)
 
insert into sgd.input_x (x_value, x_example, x_num) values (-1.7, 1, 2)
insert into sgd.input_x (x_value, x_example, x_num) values (-1.5, 2, 2)
insert into sgd.input_x (x_value, x_example, x_num) values (-1.3, 3, 2)
insert into sgd.input_x (x_value, x_example, x_num) values (-1.1, 4, 2)
insert into sgd.input_x (x_value, x_example, x_num) values (-0.9, 5, 2)
go
  
-- create table for Y values
create table sgd.y_true ([y_value] float NULL, [y_example] int NULL)
go
 
-- input test Y values
insert into sgd.y_true (y_value, y_example) values (4.77, 1)
insert into sgd.y_true (y_value, y_example) values (4.51, 2)
insert into sgd.y_true (y_value, y_example) values (4.25, 3)
insert into sgd.y_true (y_value, y_example) values (3.99, 4)
insert into sgd.y_true (y_value, y_example) values (3.73, 5)
go
 
-- create table for LR coeff
create table sgd.coeff ([w_value] float NULL, [w_num] int NULL)
go
 
-- create started W values
insert into sgd.coeff (w_value, w_num) values (.1, 0)
insert into sgd.coeff (w_value, w_num) select distinct 0.1 as w_value, x_num from sgd.input_x
go
 
-- create table for saving information about coeff in learning circle
create table sgd.coeff_learning ([w_value] float NULL, [w_num] int NULL, [iter] int NULL)
go
 
-- create table for saving information about errors in learning circle
create table sgd.error_learning ([error_SGD] float NULL, [example] int NULL, [iter] int NULL)
go
 
-- fuction of updating W1..Wn coeffs of LR
CREATE FUNCTION [sgd].[update_w]
(     
       @alpha float,
       @error_SGD float
)
RETURNS TABLE
AS
RETURN
(
       select t2.w_value - t1.x_value * @alpha * @error_SGD as new_w, t2.w_num  from
       (select * from [PROMBDCKMZ].[sgd].[input_x] where x_example=1) t1
       inner join
       [PROMBDCKMZ].[sgd].[coeff] t2
       on t1.x_num=t2.w_num
)
go
 
-- fuction of prediction y using actual W coeffs
CREATE FUNCTION [sgd].[predict]
(
       @example int
)
RETURNS TABLE
AS
RETURN
(
       select x_value * (SELECT w_value FROM [PROMBDCKMZ].[sgd].[coeff] where w_num=1) + (SELECT w_value FROM [PROMBDCKMZ].[sgd].[coeff] where w_num=0) as y_predict
       from [PROMBDCKMZ].[sgd].[input_x]
       where x_example=@example
)
go