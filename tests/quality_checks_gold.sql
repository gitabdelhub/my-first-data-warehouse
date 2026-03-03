/*
===============================================================================
Contrôles Qualité — Couche Gold
===============================================================================
Objectif du script :
    Ce script effectue des contrôles qualité pour valider l'intégrité, la cohérence 
    et l'exactitude de la couche Gold. Ces vérifications garantissent :
    - L'unicité des clés de substitution dans les tables de dimensions.
    - L'intégrité référentielle entre la table de faits et les tables de dimensions.
    - La validation des relations du modèle de données à des fins analytiques.
Notes d'utilisation :
    - Analyser et résoudre toute anomalie détectée lors des contrôles.
===============================================================================
*/

-- ====================================================================
-- Vérification de 'gold.dim_customers'
-- ====================================================================
-- Vérifier l'unicité de la clé client dans gold.dim_customers
-- Résultat attendu : Aucun résultat
SELECT 
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Vérification de 'gold.dim_products'
-- ====================================================================
-- Vérifier l'unicité de la clé produit dans gold.dim_products
-- Résultat attendu : Aucun résultat
SELECT 
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ====================================================================
-- Vérification de 'gold.fact_sales'
-- ====================================================================
-- Vérifier la connectivité du modèle de données entre la table de faits et les dimensions
-- Résultat attendu : Aucun résultat (aucune clé orpheline)
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL 
   OR c.customer_key IS NULL;