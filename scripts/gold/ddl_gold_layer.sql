/*
===============================================================================
Script DDL : Création des Vues Gold
===============================================================================
Objectif du script :
    Ce script crée les vues pour la couche Gold de l'entrepôt de données. 
    La couche Gold représente les tables de faits et de dimensions finales (Schéma en étoile).
    Chaque vue effectue des transformations et combine les données de la couche Silver 
    pour produire un ensemble de données propre, enrichi et prêt pour l'analyse métier.
Utilisation :
    - Ces vues peuvent être interrogées directement pour l'analyse et le reporting.
===============================================================================
*/

-- =============================================================================
-- Création de la Dimension : gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS cle_client,        -- Clé de substitution
    ci.cst_id                           AS id_client,
    ci.cst_key                          AS numero_client,
    ci.cst_firstname                    AS prenom,
    ci.cst_lastname                     AS nom,
    la.cntry                            AS pays,
    ci.cst_marital_status               AS statut_marital,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr           
        ELSE COALESCE(ca.gen, 'n/a')                          
    END                                 AS genre,
    ca.bdate                            AS date_naissance,
    ci.cst_create_date                  AS date_creation
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- =============================================================================
-- Création de la Dimension : gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS cle_produit,  -- Clé de substitution
    pn.prd_id       AS id_produit,
    pn.prd_key      AS numero_produit,
    pn.prd_nm       AS nom_produit,
    pn.cat_id       AS id_categorie,
    pc.cat          AS categorie,
    pc.subcat       AS sous_categorie,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cout,
    pn.prd_line     AS gamme,
    pn.prd_start_dt AS date_debut
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL;  -- Filtrer toutes les données historiques
GO

-- =============================================================================
-- Création de la Dimension : gold.dim_date                         
-- =============================================================================
IF OBJECT_ID('gold.dim_date', 'V') IS NOT NULL
    DROP VIEW gold.dim_date;
GO
CREATE VIEW gold.dim_date AS
SELECT DISTINCT
    CONVERT(INT, FORMAT(sls_order_dt, 'yyyyMMdd'))  AS cle_date,        
    sls_order_dt                                    AS date,             
    DATEPART(QUARTER, sls_order_dt)                 AS trimestre,       
    'Q' + CAST(DATEPART(QUARTER, sls_order_dt)
          AS VARCHAR)                               AS label_trimestre,  
    MONTH(sls_order_dt)                             AS mois,            
    DATENAME(MONTH, sls_order_dt)                   AS nom_mois,         
    DAY(sls_order_dt)                               AS jour,            
    DATENAME(WEEKDAY, sls_order_dt)                 AS jour_semaine,    
    CASE 
        WHEN DATEPART(WEEKDAY, sls_order_dt) IN (1, 7) 
        THEN 1 ELSE 0 
    END                                             AS est_weekend       -
FROM silver.crm_sales_details
WHERE sls_order_dt IS NOT NULL;
GO

-- =============================================================================
-- Création de la Table de Faits : gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num                                      AS numero_commande,
    pr.cle_produit                                      AS cle_produit,
    cu.cle_client                                       AS cle_client,
    CONVERT(INT, FORMAT(sd.sls_order_dt, 'yyyyMMdd'))   AS cle_date,          
    sd.sls_order_dt                                     AS date_commande,
    sd.sls_ship_dt                                      AS date_livraison,
    sd.sls_due_dt                                       AS date_echeance,
    sd.sls_sales                                        AS chiffre_affaires,
    sd.sls_quantity                                     AS quantite,
    sd.sls_price                                        AS prix
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.numero_produit
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.id_client;
GO
