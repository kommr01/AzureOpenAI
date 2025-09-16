/****** Object:  StoredProcedure [dbo].[spOverDueOSTMaster]    Script Date: 6/21/2025 12:55:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spOverDueOSTMaster] (
	@p_facId INT,
	@P_END_DATE DATE = NULL,
    @p_dim1_id INT,
    @PageNumber INT = 1,
    @PageSize INT = 50,
	@p_wo_number nvarchar(255) = null,
	@p_wo_status nvarchar(255) = null,
    @p_wo_desc nvarchar(255) = null,
    @p_loc_name nvarchar(255) = null,
    @p_due_date nvarchar(255) = null,
	@p_wo_type nvarchar(255) = null,
    @p_asset_eq_type nvarchar(255) = null,
    @p_asset_eq_name  nvarchar(255) = null,
    @p_asset_item_tag_num  nvarchar(255) = null,
	@p_division_loc_name nvarchar(255) = null,
    @p_UNIT_NAME nvarchar(255) = null,
	@p_insp_type nvarchar(255) = null,
	@p_loc_crit nvarchar(255) = null,
	@p_equipment_number nvarchar(255) = null,
	@p_equipment_name nvarchar(255) = null,
	@p_comments nvarchar(255) = null
	)
AS
BEGIN
	
IF @p_facId = 2
BEGIN
	select *,COUNT(*) OVER() AS count,
    SUM(CASE when CAST(dueDate AS DATE) > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS yellowCount,
    SUM(CASE when CAST(dueDate AS DATE) <= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS redCount from(
    SELECT 
        wo_number woNumber,
        wo_status woStatus,
        wo_desc woDescription,
        loc_name unitLocName,
        Format(due_date,'dd-MMM-yyyy') dueDate,
        division_loc_name division,
        insp_type inspectionType,
        loc_crit criticality,
		(case when dc.comments is not null 
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
		else dc.comments end) as comments,  
		(case when CAST(due_date AS DATE) <= CAST(GETDATE() AS DATE) then 'Red' else  'Yellow' end) as color,
		ROW_NUMBER() over(partition by(r.wo_number) order by dc.created_dt desc) r
        FROM 
        OERI.APEX_OST_DTL_V_RIC r
		left join Dashboard_Comments dc on r.wo_number = dc.WO_NUM
        WHERE 
        loc_id_prnt = @p_facId
        AND EFFECTIVE_DATE < CONVERT(DATE, GETDATE(), 101)
		) as t
		
		order by due_date desc
END

    -- Call the OVERDUE_OST_SL stored procedure
IF @p_facId = 3
BEGIN
     select *,COUNT(*) OVER() AS count,
     SUM(CASE when CAST(dueDate AS DATE) > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS yellowCount,
     SUM(CASE when CAST(dueDate AS DATE) <= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS redCount from(
     SELECT 
        wo_number woNumber,
        wo_status woStatus,
        wo_desc woDescription,
        loc_name unitLocName,
        Format(due_date,'dd-MMM-yyyy') dueDate,
        insp_type inspectionType,
        division_name division,
        LOC_CRIT criticality,
        equipment_number equipNum,
        equipment_name equipName,
		(case when dc.comments is not null   
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
		else dc.comments end) as comments,  
		(case when CAST(due_date AS DATE) <= CAST(GETDATE() AS DATE) then 'Red' else  'Yellow' end) as color,
		ROW_NUMBER() over(partition by(r.wo_number) order by dc.created_dt desc) r
        FROM 
        OERI.APEX_OST_DTL_V_ALL r
		left join Dashboard_Comments dc on r.wo_number = dc.WO_NUM
        WHERE 
        loc_id_prnt = @p_facId
        AND EFFECTIVE_DATE < CONVERT(DATE, GETDATE(), 101)
		) as t
		
		order by due_date desc  
END
    -- Call the OVERDUE_OST_ESE stored procedure
IF @p_facId = 5
BEGIN
       select *,COUNT(*) OVER() AS count,
       SUM(CASE when CAST(dueDate AS DATE) > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS yellowCount,
       SUM(CASE when CAST(dueDate AS DATE) <= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS redCount from(
       SELECT 
        insp_src_pp_wo_nbr woNumber,
        wo_status woStatus,
        wo_desc woDescription,
        loc_name unitLocName,
        Format(due_date,'dd-MMM-yyyy') dueDate,
        DIVISION_NAME division,
		UNIT_NAME unitName,
		loc_crit criticality,
		insp_typ inspectionType,
		(case when dc.comments is not null   
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
		else dc.comments end) as comments,  
		( case when CAST(due_date AS DATE) <= CAST(GETDATE() AS DATE) then 'Red' else  'Yellow' end) as color,
		ROW_NUMBER() over(partition by(r.insp_src_pp_wo_nbr) order by dc.created_dt desc) r
		FROM 
        OERI.APEX_OST_PRD_PM_DTL_V_ESE r
		left join Dashboard_Comments dc on r.insp_src_pp_wo_nbr = dc.WO_NUM
        WHERE 
        LOC_ID_PRNT = @p_facId
        AND insp_typ IN ('OST')
		AND EFFECTIVE_DATE < CONVERT(DATE, GETDATE(), 101)
		AND EFFECTIVE_DATE >= CONVERT(DATE, '01-JAN-08', 106)
		) as t
		
		order by due_date desc 
END
  
    -- Call the OVERDUE_OST_PAS stored procedure
IF @p_facId = 6
BEGIN
      select *,COUNT(*) OVER() AS count,
      SUM(CASE when CAST(dueDate AS DATE) > CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS yellowCount,
      SUM(CASE when CAST(dueDate AS DATE) <= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) OVER() AS redCount from(
      SELECT 
        r.wo_num woNumber,
        wo_status woStatus,
        wo_desc woDescription,
        loc_name unitLocName,
        Format(due_date,'dd-MMM-yyyy') dueDate,
        wo_type woType,
		asset_eq_type assetEqType,
		asset_eq_name assetEqName,
		asset_item_tag_num assetItemTagNum,
		section_loc_name division,
		unit_loc_name unitName,
        loc_crit criticality,
		(case when dc.comments is not null   
		then concat(convert(varchar(50),format(dc.created_dt,'dd/MM/yyyy')), ' - ', dc.Changed_By, ' : ' , dc.Comments)  
		else dc.comments end) as comments,  
		(case when CAST(due_date AS DATE) <= CAST(GETDATE() AS DATE) then 'Red' else  'Yellow' end) as color,
		ROW_NUMBER() over(partition by(r.wo_num) order by dc.created_dt desc) r
        FROM 
        OERI.APEX_OST_DTL_V_PAS r
		left join Dashboard_Comments dc on r.wo_num = dc.WO_NUM
        WHERE 
        loc_id_prnt = @p_facId
        AND DUE_DATE < CONVERT(DATE, GETDATE(), 101)
		) as t
		
		order by due_date desc     
END
    -- Add more EXEC calls as needed for other stored procedures
END
