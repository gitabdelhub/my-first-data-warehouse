/*
===============================================================================
Contrôles de Qualité
===============================================================================
Objectif du script :
    Ce script effectue plusieurs contrôles de qualité pour vérifier la cohérence,
    l’exactitude et la standardisation des données dans la couche 'silver'.
    Il inclut des vérifications pour :
    - Les clés primaires NULL ou dupliquées.
    - Les espaces indésirables dans les champs texte.
    - La standardisation et la cohérence des données.
    - Les plages de dates invalides et les ordres de dates incorrects.
    - La cohérence des données entre champs liés.

Notes d'utilisation :
    - Exécuter ces contrôles après le chargement de la couche Silver.
    - Examiner et corriger toute anomalie détectée.
===============================================================================
*/

-- ====================================================================
-- Vérification de 'silver.crm_cust_info'
-- ====================================================================

-- Vérifier les NULL ou les doublons dans la clé primaire
-- Attendu : Aucun résultat
SELECT 
    cst_id,
    COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Vérifier les espaces indésirables
-- Attendu : Aucun résultat
SELECT 
    cst_key 
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- Standardisation et cohérence des données
SELECT DISTINCT 
    cst_marital_status 
FROM silver.crm_cust_info;


-- ====================================================================
-- Vérification de 'silver.crm_prd_info'
-- ====================================================================

-- Vérifier les NULL ou les doublons dans la clé primaire
-- Attendu : Aucun résultat
SELECT 
    prd_id,
    COUNT(*) 
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Vérifier les espaces indésirables
-- Attendu : Aucun résultat
SELECT 
    prd_nm 
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- Vérifier les valeurs NULL ou négatives du coût
-- Attendu : Aucun résultat
SELECT 
    prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Standardisation et cohérence des données
SELECT DISTINCT 
    prd_line 
FROM silver.crm_prd_info;

-- Vérifier les ordres de dates invalides (Date début > Date fin)
-- Attendu : Aucun résultat
SELECT 
    * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- ====================================================================
-- Vérification de 'silver.crm_sales_details'
-- ====================================================================

-- Vérifier les dates invalides
-- Attendu : Aucune date invalide
SELECT 
    NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
    OR LEN(sls_due_dt) != 8 
    OR sls_due_dt > 20500101 
    OR sls_due_dt < 19000101;

-- Vérifier les ordres de dates invalides (Date commande > Date livraison/échéance)
-- Attendu : Aucun résultat
SELECT 
    * 
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt 
   OR sls_order_dt > sls_due_dt;

-- Vérifier la cohérence des données : Ventes = Quantité * Prix
-- Attendu : Aucun résultat
SELECT DISTINCT 
    sls_sales,
    sls_quantity,
    sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL 
   OR sls_quantity IS NULL 
   OR sls_price IS NULL
   OR sls_sales <= 0 
   OR sls_quantity <= 0 
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- ====================================================================
-- Vérification de 'silver.erp_cust_az12'
-- ====================================================================

-- Identifier les dates hors intervalle
-- Attendu : Dates de naissance entre 1924-01-01 et aujourd’hui
SELECT DISTINCT 
    bdate 
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' 
   OR bdate > GETDATE();

-- Standardisation et cohérence des données
SELECT DISTINCT 
    gen 
FROM silver.erp_cust_az12;


-- ====================================================================
-- Vérification de 'silver.erp_loc_a101'
-- ====================================================================

-- Standardisation et cohérence des données
SELECT DISTINCT 
    cntry 
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ====================================================================
-- Vérification de 'silver.erp_px_cat_g1v2'
-- ====================================================================

-- Vérifier les espaces indésirables
-- Attendu : Aucun résultat
SELECT 
    * 
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) 
   OR subcat != TRIM(subcat) 
   OR maintenance != TRIM(maintenance);

-- Standardisation et cohérence des données
SELECT DISTINCT 
    maintenance 
FROM silver.erp_px_cat_g1v2;