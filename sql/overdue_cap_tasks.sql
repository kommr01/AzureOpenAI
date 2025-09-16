/****** Object:  StoredProcedure [dbo].[spOverdueCapTasks]    Script Date: 6/21/2025 1:04:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spOverdueCapTasks] (
	@p_facId INT,
	@p_dim1_id INT,
    @p_end_date DATETIME =null,
	@pageNumber int =1,
	@pageSize int=50,
    @p_comments NVARCHAR(255) = NULL,
    -- RIC,SL,PA
    @p_jobId NVARCHAR(255) = NULL,
    @p_jobTitle NVARCHAR(255) = NULL,
    @p_taskId NVARCHAR(255) = NULL,
    @p_taskDescription NVARCHAR(255) = NULL,
    @p_location NVARCHAR(255) = NULL,
    @p_dueDate NVARCHAR(255) = NULL,
    -- ES
    @p_taskNumber NVARCHAR(255) = NULL,
    @p_taskLocation NVARCHAR(255) = NULL,
    @p_status NVARCHAR(255) = NULL,
    @p_reviewDate NVARCHAR(255) = NULL
)
AS
BEGIN
	
	-- Call the OVERDUE_CAP_TASKS RIC,SL and PA
    IF @p_facId IN (2, 3, 6)
BEGIN
    SELECT *
    FROM (
            SELECT 
                LOC_NAME AS location,
                x.CAP_JOB_ID AS jobId,
                CAP_JOB_TITLE AS jobTitle,
                CAP_TASK_ID AS taskId,
                REPLACE(CAP_TASK_DESC, CHAR(10), CHAR(46)) AS taskDescription,   
                Format(DT_FULL_DATE,'dd-MMM-yyyy') dueDate,
                DT_FULL_DATE AS rawDueDate,
				(case when dc.comments is not null   
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
	 else dc.comments end) as comments,
	 (
case when CAST(DT_FULL_DATE AS DATE) <= CAST(GETDATE() AS DATE) then 'Red'
else  'Yellow'
end
) as color,
	 ROW_NUMBER() over(partition by(x.cap_job_id) order by dc.created_dt desc) r  
            FROM OERI.APEX_CAP_DTL_V_ALL x
			left join Dashboard_Comments dc on x.CAP_TASKS_COMPOSITE_KEY = dc.CAP_TASKS_COMP_KEY
            WHERE LOC_ID_PRNT = @p_dim1_id
            AND DT_FULL_DATE < CONVERT(DATE, GETDATE(), 101)
            
            UNION ALL
            
            SELECT 
                LOC_NAME AS location,
                x.CAP_JOB_ID AS capJobId,
                CAP_JOB_TITLE AS capJobTitle,
                CAP_TASK_ID AS capTaskId,
                REPLACE(CAP_TASK_DESC, CHAR(10), CHAR(46)) AS capTaskDesc,
                Format(DT_FULL_DATE,'dd-MMM-yyyy') fullDate,
                DT_FULL_DATE AS rawDueDate,
				(case when dc.comments is not null   
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
	 else dc.comments end) as comments,
	 (
case when CAST(DT_FULL_DATE AS DATE) <= CAST(GETDATE() AS DATE) then 'Red'
else  'Yellow'
end
) as color,
	 ROW_NUMBER() over(partition by(x.cap_job_id) order by dc.created_dt desc) r  
            FROM OERI.APEX_CAP_DTL_V_ESE x
		    left join Dashboard_Comments dc on x.CAP_TASKS_COMPOSITE_KEY = dc.CAP_TASKS_COMP_KEY

            WHERE LOC_ID_PRNT = @p_facId
            AND DT_FULL_DATE < CONVERT(DATE, GETDATE(), 101)
           
            ) AS subquery
       
        ORDER BY rawDueDate DESC
       
    END

-- Call the OVERDUE_CAP_TASKS ES
    IF @p_facId = 5
    BEGIN
        SELECT *,count(*) over() as count,
SUM(CASE when CAST(fullDate AS DATE) > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS yellowCount,
SUM(CASE when CAST(fullDate AS DATE) <= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS redCount FROM(
            SELECT 
			x.CAP_JOB_ID as capJobId,
                CAP_TASK_PLANT AS capTaskPlant,
                CAP_JOB_TITLE AS capJobTitle,
                CAP_TASK_SECTION AS capTaskSection,
                REPLACE(CAP_TASK_DESC, CHAR(10), CHAR(46)) AS capTaskDesc,
                Format(REVIEW_DATE,'dd-MMM-yyyy') reviewDate,
                Format(DT_FULL_DATE,'dd-MMM-yyyy') fullDate	,
				(case when dc.comments is not null   
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
	 else dc.comments end) as comments,
	 (
case when CAST(DT_FULL_DATE AS DATE) <= CAST(GETDATE() AS DATE) then 'Red'
else  'Yellow'
end
) as color,
	 ROW_NUMBER() over(partition by(x.cap_job_id) order by dc.created_dt desc) r
            FROM OERI.APEX_CAP_DTL_V_ESE x
		   left join Dashboard_Comments dc on x.CAP_TASKS_COMPOSITE_KEY = dc.CAP_TASKS_COMP_KEY
            WHERE LOC_ID_PRNT = @p_facId
            AND DT_FULL_DATE < CONVERT(DATE, GETDATE(), 101)
            
        ) AS subquery
        
        
        ORDER BY DT_FULL_DATE DESC
       
    END
  
END
