-- select DB you want to use
use PROMBD
 
-- off information messages
SET NOCOUNT ON
 
declare @max_iteration int -- after the itteration more then this algoritm will stop
set @max_iteration=30 -- constant
 
declare @max_error float -- after the error less then this algoritm will stop
set @max_error=0.00002 -- constant
 
declare @alpha float -- speed of the algoritm
set @alpha=0.02 -- constant
 
declare @error_SGD float -- error on this  itteration
set @error_SGD=0.1 -- init value
 
declare @error_SGD_prev float -- error on the previous itteration
set @error_SGD_prev=-10 -- init value
 
declare @dif_error_SGD float -- error between this itteration and previous
set @dif_error_SGD=0.1 -- init value
 
declare @iteration int -- number of the algoritm itteration
set @iteration=0 -- init value

declare @example int -- number of example that used in the itteration of the algoritm
set @example=0 -- init value

declare @b0 float -- bias
declare @y_predict float -- predicted y on this itteration of the algoritm
declare @y_true float -- real y on this itteration of the algoritm

declare @min_error float -- minimal error in the live circle of the algoritm
set @min_error=100 -- init value

declare @min_error_iter float -- itteration of minimal error in the live circle of the algoritm
set @min_error_iter=0 -- init value

-- init start weights of the algoritm
update [sgd].[coeff] set [w_value]=.01
 
while @iteration<@max_iteration and abs(@dif_error_SGD)>@max_error

begin
       -- calc diff error with previuos itteration
       set @dif_error_SGD = abs(@error_SGD-@error_SGD_prev)
       set @error_SGD_prev = @error_SGD
	   
       -- next itteration
       set @iteration = @iteration + 1

       -- next num of x
       select @example =
             case
                    when 1+@example>(SELECT count(distinct [x_example]) FROM [sgd].[input_x]) then 1
                    else 1+@example
             end

       -- calc prediction and error on this itteration
       SELECT @y_true = [y_value] FROM [sgd].[y_true] where y_example=@example
       SELECT @y_predict = y_predict FROM [sgd].[predict](@example)
       set @error_SGD = @y_predict - @y_true

       -- new bias coeff value
       set @b0 = (select [w_value] FROM [sgd].[coeff] where [w_num]=0) - @alpha * @error_SGD
       update [sgd].[coeff] set w_value=round(@b0,8) where w_num=0
	   
       -- update w coeff by new value
       update [sgd].[coeff]
		set [sgd].[coeff].w_value=round(new_w,8)
		from [sgd].[update_w] (@alpha, @error_SGD) t1
		inner join [sgd].[coeff] t2
		on t1.w_num=t2.w_num

       -- history log of learning
       insert into sgd.coeff_learning select w_value, w_num, @iteration as iter from sgd.coeff
       insert into sgd.error_learning (error_SGD, example, iter) values (abs(@error_SGD), @example, @iteration)

       -- update information of the minimal error and itteration
       if abs(@error_SGD)<abs(@min_error) set @min_error_iter=@iteration
       if abs(@error_SGD)<abs(@min_error) set @min_error=abs(@error_SGD)
end

--information about min error and iteration of it
print 'Minimal Error - ' + cast(abs(@min_error) as varchar) + '; Itteration of minimal error - '+  cast(abs(@min_error_iter) as varchar) + '.'