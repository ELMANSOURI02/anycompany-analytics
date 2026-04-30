                                       Architecture Big Data — ESG MBA 2026
**Projet** : Data-Driven Marketing Analytics
**Équipe** : El Mansouri Nada, Laifa Djazira, Abakhchouch Basma
**Formation** : ESG MBA — Architecture Big Data 2026
**Stack** : Snowflake (BRONZE / SILVER / ANALYTICS) + Streamlit


-Synthèse exécutive:

Cette analyse exploite les données opérationnelles d'AnyCompany (ventes, promotions, campagnes marketing, clients, logistique, service client) pour produire des recommandations stratégiques actionnables. Les données ont été ingérées depuis Amazon S3, nettoyées dans Snowflake selon une architecture en médaillon (Bronze → Silver → Analytics), puis analysées via SQL et restituées dans trois dashboards Streamlit.

**Trois leviers de croissance ont été identifiés** : 
1 un rééquilibrage régional du mix promotionnel
2 une réallocation budgétaire des campagnes marketing vers les canaux à plus fort ROI
3 une segmentation client plus fine pour réduire le churn et augmenter la valeur vie client.



1. Performance commerciale

-Constats:
    - Évolution des ventes mensuelles avec une saisonnalité marquée sur les pics [Q4 / périodes promotionnelles].
    - La région **[région leader]** concentre `[X %]` du chiffre d'affaires total, contre `[Y %]` pour la région la moins performante.
    - Le panier moyen varie de `[X €]` à `[Y €]` selon le mode de paiement, avec une corrélation forte entre paiement digital et panier élevé.

-Recommandations:
- Renforcer la présence dans les régions sous-performantes, par des campagnes ciblées plutôt que de saturer les régions matures.
- Promouvoir activement les modes de paiement digitaux (CB, mobile) qui génèrent un panier moyen supérieur de `[X %]`.
- Mettre en place un suivi MoM/YoY hebdomadaire dans le dashboard pour détecter les inflexions de tendance.


2. Impact des promotions

-Constats:
- L'uplift moyen des ventes pendant une promotion est de `[X %]` par rapport à la baseline hors promo.
- Les promotions sur la catégorie **catégorie la plus réactive** génèrent un uplift de `[X %]`, contre seulement `[Y %]` pour **catégorie la moins réactive** — preuve que toutes les catégories ne réagissent pas de la même façon aux remises.
- Le taux de remise optimal se situe autour de `[X %]` : au-delà, l'uplift marginal diminue alors que la marge se dégrade.
- Les promotions de durée `[X jours]` affichent le meilleur ratio efficacité/coût.

-Recommandations:
- Concentrer le budget promotionnel sur les catégories à forte élasticité (top 3) plutôt que de saupoudrer.
- Plafonner les remises à `[X %]` pour préserver la marge sans perdre l'effet d'attraction.
- Tester en A/B des promotions courtes (3-5 jours) vs longues (10+ jours) pour confirmer la durée optimale par segment.
- Éviter les promotions superposées qui cannibalisent l'uplift réel.



3. ROI des campagnes marketing

-Constats:
- Le canal canal #1 affiche le ROI le plus élevé (`[X €]` générés pour `[1 €]` investi), suivi de canal #2
- À l'inverse, le canal canal le moins rentable présente un ROI inférieur à 1 — il détruit de la valeur.
- Les campagnes ciblant l'audience segment gagnant convertissent `[X fois]` mieux que la moyenne.
- Corrélation positive observée entre intensité des campagnes et ventes des 7 jours suivants (`r = [X]`).

-Recommandations:
- **Réallouer `[X %]` du budget** des canaux à faible ROI vers les canaux performants — gain potentiel estimé à `[X €]` sur l'année.
- **Industrialiser le ciblage** sur le segment d'audience le plus rentable (lookalike, retargeting).
- **Arrêter ou refondre** les campagnes dont le ROI est < 1 après 2 cycles consécutifs.
- Mesurer systématiquement l'effet retardé (lag de 3 à 7 jours) pour ne pas sous-estimer l'impact d'une campagne.


4. Connaissance client et fidélisation

-Constats:
- La segmentation par âge × revenu × ancienneté révèle 4 segments distincts, dont un segment clients à risque de churn représentant `[X %]` de la base.
- Les clients ayant noté un produit ≤ 2 étoiles ont un taux de réachat inférieur de `[X %]` aux clients satisfaits.
- Les clients à forte ancienneté (`tenure > [X] ans`) génèrent un panier moyen `[X %]` supérieur — la rétention paie.

-Recommandations:
- Programme de rétention ciblé sur le segment churn-risk : offre personnalisée, contact proactif du service client.
- Boucle de feedback produit : tout client donnant ≤ 2 étoiles doit être recontacté sous 48h.
- Programme de fidélité étagé récompensant l'ancienneté et le panier moyen — meilleur levier de LTV identifié.


5. Service client et qualité opérationnelle

-Constats:
- Le délai moyen de résolution des tickets est de `[X heures]`, avec une longue traîne de tickets non résolus > `[X jours]`.
- Les motifs de contact les plus fréquents sont motif #1 et motif #2, qui représentent à eux seuls `[X %]` du volume.
- Forte corrélation entre satisfaction service client et taux de réachat à 90 jours.

-Recommandations:
- Automatiser le top 2 des motifs récurrents (FAQ enrichie, chatbot, self-service) pour libérer les agents sur les cas complexes.
- SLA strict : aucun ticket > 72h sans escalade automatique.
- Intégrer le NPS post-interaction dans le dashboard pour piloter la qualité en temps réel.


6. Logistique et chaîne d'approvisionnement

-Constats:
- Le délai moyen de livraison est de `[X jours]`, avec des écarts régionaux significatifs (de `[X]` à `[Y]` jours selon la région).
- `[X %]` des livraisons dépassent le délai promis — impact direct sur les notes produits et le service client.
- Quelques fournisseurs concentrent les retards : `[X %]` des retards proviennent de `[Y %]` des fournisseurs.

-Recommandations:
- Renégocier les SLA avec les fournisseurs identifiés comme générateurs de retards.
- Diversifier le sourcing sur les catégories à risque (single-supplier dependency).
- Plan d'optimisation logistique régional sur les zones les plus en retard — gain estimé : amélioration des notes produits de `[X %]`.

-Synthèse des priorités:

| Priorité | Action | Impact attendu | Horizon |
|----------|--------|----------------|---------|
| 🔴 1 | Réallouer le budget marketing vers les canaux à ROI > 1 | +`[X €]` de revenus | 3 mois |
| 🔴 2 | Plafonner les remises promo à `[X %]` sur catégories ciblées | +`[X pts]` de marge | 1 mois |
| 🟠 3 | Programme de rétention sur segment churn-risk | -`[X %]` de churn | 6 mois |
| 🟠 4 | Automatisation top 2 motifs service client | -`[X %]` de tickets | 3 mois |
| 🟡 5 | Renégociation SLA fournisseurs en retard | +`[X %]` ponctualité | 6 mois |


-Limites et prochaines étapes:

- Données disponibles: limitées à la période fournie ; une analyse pluriannuelle affinerait la saisonnalité.
- Pas de données concurrentielles : les uplifts mesurés intègrent un effet marché non isolé.
- Prochaines itérations : modèle prédictif de churn (ML), attribution multi-touch des campagnes, optimisation dynamique des promotions.


