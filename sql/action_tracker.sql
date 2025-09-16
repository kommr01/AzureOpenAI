/****** Object:  StoredProcedure [dbo].[spUspManageResponsibilities]    Script Date: 6/23/2025 1:18:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





ALTER PROCEDURE [dbo].[spUspManageResponsibilities] 
    @q_facid VARCHAR (MAX)= NULL,
    @owner VARCHAR (MAX)= NULL,
    @q_ITEM_TYPE VARCHAR (MAX)= NULL,
    @q_division bigint = NULL,
    @q_unit VARCHAR (MAX)= NULL,
    @q_area VARCHAR (MAX)= NULL,
    @q_STUDY_TYPE VARCHAR (MAX)= NULL,
    @q_status VARCHAR (MAX) = NULL,
    @q_DUE_DAYS VARCHAR (MAX) = NULL,
    @taReqd VARCHAR (MAX)= NULL,
	@PageSize INT = 50, -- Default page size is 10  
	@PageNumber INT = 1, -- Default  
	@q_color_filter VARCHAR(MAX) = NULL, -- New parameter for color filter
	@q_ownername VARCHAR(MAX) = NULL,
	@q_itemtype VARCHAR(MAX) = NULL,
	@q_div VARCHAR(MAX) = NULL,
	@q_uni VARCHAR(MAX) = NULL,
	@q_location VARCHAR(MAX) = NULL,
	@title VARCHAR(MAX) = NULL,
	@q_description VARCHAR(MAX) = NULL,
	@dateassigned VARCHAR(MAX) = NULL,
	@duedate VARCHAR(MAX) = NULL,
	@q_overallstatus VARCHAR(MAX) = NULL,
	@q_statu VARCHAR(MAX) = NULL,
	@q_itemage VARCHAR(MAX) = NULL,
	@q_ref VARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @q_top NVARCHAR(MAX),
        @q_from NVARCHAR(MAX),
        @q_where NVARCHAR(MAX),
        @q_big NVARCHAR(MAX);

    -- Constructing the query parts
    SET @q_top = 'SELECT 
	a.OWNER_NAME as ownername, 
	a.ITEM_TYPE as itemtype, 
	a.DIV_NAME as division, 
	a.UNIT_NAME as unit, 
	a.location_id as location, 
	a.DESCRIPTION as description,
	FORMAT(a.DATE_ASSIGNED,''dd-MMM-yyyy'') as date_assinged , 
    FORMAT(a.DUE_DATE,''dd-MMM-yyyy'') as due_date, 
	FORMAT(a.COMPLETED_DATE,''dd-MMM-yyyy'') as completed_date, 
	a.FAC_ID as facid, 
	a.actual_status as actual_status, 
	a.STATUS as  status, 
    a.ID_VAL as id_val,
	a.PERSON_ID AS person_id,
    CASE WHEN a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' THEN ''RED''
    WHEN a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' THEN ''Yellow''
    when a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' THEN ''BLACK'' 
	ELSE ''NULL'' END AS color,
    DATEDIFF(DAY, CAST(a.date_assigned AS DATE), CAST(GETDATE() AS DATE)) AS item_age,
	SUM(CASE WHEN a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' THEN 1 ELSE 0 END) OVER() AS redCount,
	SUM(CASE when a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' THEN 1 ELSE 0 END) OVER() AS yellowCount,
	SUM(CASE when a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' THEN 1 ELSE 0 END) OVER() AS blackCount,
	SUM(CASE when a.status = ''Open'' THEN 1 ELSE 0 END) OVER() AS totalCounts,
    SUM(CASE when a.status = ''Open'' and a.actual_status = ''Resolved'' THEN 1 ELSE 0 END) OVER() AS resolvedcount,
	SUM(CASE when a.status = ''Open'' and a.actual_status = ''On Hold'' THEN 1 ELSE 0 END) OVER() AS onholdcount,
	SUM(CASE WHEN a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' and a.actual_status = ''On Hold'' THEN 1 ELSE 0 END) OVER() AS redonholdcount,
    SUM(CASE when a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''On Hold'' THEN 1 ELSE 0 END) OVER() AS yellowonholdcount,
    SUM(CASE when a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''On Hold'' THEN 1 ELSE 0 END) OVER() AS blackonholdcount,
	SUM(CASE when a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' and a.actual_status = ''Identified / Pending Evaluation'' THEN 1 ELSE 0 END) OVER() AS ideredcount,
	SUM(CASE when a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' and a.actual_status = ''Approved to proceed (not started or deferred)'' THEN 1 ELSE 0 END) OVER() AS approvedredcount,
	SUM(CASE when a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' and a.actual_status = ''Active (in progress)'' THEN 1 ELSE 0 END) OVER() AS activeredcount,
	SUM(CASE when a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''Identified / Pending Evaluation'' THEN 1 ELSE 0 END) OVER() AS ideyellowcount,
	SUM(CASE when a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''Approved to proceed (not started or deferred)'' THEN 1 ELSE 0 END) OVER() AS approvedyellowcount,
	SUM(CASE when a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''Active (in progress)'' THEN 1 ELSE 0 END) OVER() AS activeyellowcount,
    SUM(CASE when a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''Identified / Pending Evaluation'' THEN 1 ELSE 0 END) OVER() AS ideblackcount,
	SUM(CASE when a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''Approved to proceed (not started or deferred)'' THEN 1 ELSE 0 END) OVER() AS approvedblackcount,
	SUM(CASE when a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' and a.actual_status = ''Active (in progress)'' THEN 1 ELSE 0 END) OVER() AS activeblackcount,
	a.ITEM_SUB_TYPE as item_sub_type, 
	a.parent_id as parent_id, 
	a.reference_number as reference, 
	a.title as title,
	a.ta_reqd as tareqd,
	COUNT(*) OVER() AS count ';

    SET @q_from = ' FROM oeri.APEX_MY_RESPONSIBILITIES AS a ';
    --SET @q_where = ' WHERE 1 = 1 AND a.FAC_ID = ' + ISNULL(@q_facid, '') + ' AND a.UNIT_LOC_ID = L.UNIT_LOC_ID ';
	IF (ISNUMERIC(@q_facid) = 1)
		SET @q_where = ' WHERE 1 = 1 AND a.FAC_ID = ' + CAST(@q_facid AS VARCHAR) ;
	ELSE
		SET @q_where = ' WHERE 1 = 1';

    -- Conditional logic for owner filtering
    
    -- Additional conditions based on FID
    IF (@q_facid = 2)
    BEGIN
        SET @q_from += ', OERI.loc_unit_lov_mv_ric AS L';
        IF (@q_division <> -1) 
		SET @q_where = CONCAT(@q_where, ' AND L.DIV_LOC_ID =', CAST(@q_division AS varchar(max)));
        IF (@q_area <> -1) 
		SET @q_where = CONCAT(@q_where, ' AND L.UNIT_GRP_LOC_ID  = ''', @q_area,'''');
    END
    ELSE IF (@q_facid IN (8, 7, 3, 9))
    BEGIN
        SET @q_from += ', OERI.loc_report_mv AS L';
        IF (@q_division <> -1) 
		BEGIN
            IF ISNUMERIC(@q_division) = 1
                SET @q_where = CONCAT(@q_where, ' AND L.DIV_LOC_ID =', CAST(@q_division AS varchar(max)));
            ELSE
                -- Handle the case where @q_division is not a number.  
                -- You might want to log an error, skip the filter, or return an error.
                SET @q_where = @q_where  --skip the filter
        END
        IF (@q_area <> -1) 
		SET @q_where = CONCAT(@q_where, ' AND L.UNIT_GRP_LOC_ID  = ''', @q_area,'''');
    END
    ELSE IF (@q_facid = 6)
    BEGIN
        SET @q_from += ', OERI.loc_unit_lov_mv_pas AS L';
        IF (@q_division <> -1) 
		BEGIN
            IF ISNUMERIC(@q_division) = 1
                SET @q_where = CONCAT(@q_where, ' AND L.section_loc_id =', CAST(@q_division AS varchar(max)));
            ELSE
                -- Handle the case where @q_division is not a number.  
                -- You might want to log an error, skip the filter, or return an error.
                SET @q_where = @q_where  --skip the filter
        END
        IF (@q_area <> -1) 
		SET @q_where = CONCAT(@q_where, ' AND L.DIV_LOC_ID  = ''', @q_area,'''');
    END
    ELSE
    BEGIN
        SET @q_from += ', OERI.loc_report_mv AS L';
        IF (@q_division <> -1) 
		BEGIN
            IF ISNUMERIC(@q_division) = 1
                SET @q_where = CONCAT(@q_where, ' AND L.DIV_LOC_ID =', CAST(@q_division AS varchar(max)));
            ELSE
                -- Handle the case where @q_division is not a number.  
                -- You might want to log an error, skip the filter, or return an error.
                SET @q_where = @q_where  --skip the filter
        END
        IF (@q_area IS NOT NULL)
		BEGIN
            IF (@q_area = '1')
			BEGIN
			    SET @q_where = CONCAT(@q_where, ' AND L.PLANT_LOC_ID  = ''', @q_area,'''');
			END
            ELSE
                -- Handle the case where @q_division is not a number.  
                -- You might want to log an error, skip the filter, or return an error.
                SET @q_where = @q_where  --skip the filter
        END
	    --SET @q_where = CONCAT(@q_where, ' AND L.PLANT_LOC_ID = ', CAST(@q_area AS varchar(max)));

    END;

   -- Item type filtering logic
  

   -- Study type filter
   
   -- Status filtering logic
     IF (ISNULL(@q_status, '') LIKE '%OPEN%')
   BEGIN 
       SET @q_where += ' AND ISNULL(STATUS, ''x'') != ''Closed'' ';
   END
   ELSE IF (ISNULL(@q_status, '') LIKE '%CLOSED%')
   BEGIN 
       SET @q_where += ' AND ISNULL(STATUS, ''x'') = ''Closed'' ';
   END
   ELSE IF (ISNULL(@q_status, '') LIKE '%OVERDUE%')
   BEGIN 
       SET @q_where += ' AND ISNULL(STATUS, ''x'') != ''Closed'' AND a.due_date < CAST(GETDATE() AS DATE)';
   END;

   -- Unit location filter
   IF (@q_unit IS NOT NULL)
   BEGIN
   	    SET @q_where = CONCAT(@q_where, ' AND a.UNIT_LOC_ID = ''', @q_unit,'''');
   END;

   -- Due days filter
   IF (@q_DUE_DAYS IS NOT NULL)
   BEGIN
  SET @q_where += ' AND a.DUE_DATE < CAST(DATEADD(DAY, '+ CAST(@q_DUE_DAYS AS nvarchar(max)) +', GETDATE()) AS DATE)';
  END;

   -- TA required filter
   IF (@taReqd IS NOT NULL)
   BEGIN
       SET @q_where =CONCAT(@q_where, ' AND UPPER(a.ta_reqd) LIKE ''' + UPPER(REPLACE(@taReqd, '''', '''''')) + '''',@taReqd);
   END;

   --color filter
    IF (@q_color_filter IS NOT NULL)
   BEGIN
       SET @q_where += ' AND CASE WHEN a.due_date < CAST(GETDATE() AS DATE) AND a.status = ''Open'' THEN ''RED''
                                    WHEN a.due_date BETWEEN CAST(GETDATE() AS DATE) AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' THEN ''Yellow''
                                    WHEN a.due_date BETWEEN DATEADD(DAY, 7, CAST(GETDATE() AS DATE)) AND DATEADD(DAY, 30, CAST(GETDATE() AS DATE)) AND a.status = ''Open'' THEN ''BLACK'' 
                                    ELSE ''NULL'' END = ''' + REPLACE(@q_color_filter, '''', '''''') + '''';
   END;

   -- Set the filter for all the data.
   


   -- Combine all parts of the query into one string.
   SET @q_big = CONCAT(@q_top,@q_from,@q_where)
   --RAISERROR(@q_big, 0, 1) WITH NOWAIT; 
   --SELECT @q_big AS [FullQuery];
   -- Create new table from the results of the query.
   EXEC sp_executesql @q_big,
    N'@q_facid VARCHAR (MAX), 
	@q_ownername VARCHAR (MAX), 
	@q_itemtype VARCHAR (MAX), 
    @PageSize INT,
	@PageNumber INT,
	@q_div VARCHAR (MAX), 
	@q_uni VARCHAR (MAX), 
	@q_location VARCHAR (MAX), 
	@title VARCHAR (MAX), 
	@q_description VARCHAR (MAX), 
	@dateassigned VARCHAR (MAX), 
	@duedate VARCHAR (MAX), 
	@q_overallstatus VARCHAR (MAX), 
	@q_statu VARCHAR (MAX), 
	@q_itemage VARCHAR (MAX), 
	@q_ref VARCHAR (MAX)',
    @q_facid, 
	@q_ownername, 
	@q_itemtype, 
    @PageSize ,
	@PageNumber ,
	@q_div, 
	@q_uni , 
	@q_location , 
	@title, 
	@q_description , 
	@dateassigned , 
	@duedate, 
	@q_overallstatus , 
	@q_statu , 
	@q_itemage , 
	@q_ref;
END
