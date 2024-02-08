
import pandas as pd


from sklearn.cluster import MiniBatchKMeans
from sklearn.decomposition import IncrementalPCA
from sklearn.metrics import silhouette_score

import matplotlib.pyplot as plt
import seaborn as sns

nft_trades = pd.read_csv('nft_traders_dune.csv')


features = ['TOTAL_USD_AMOUNT_TRADED', 'TOTAL_TRADE_COUNT', 'UNIQUE_NFT_TRADED', 'TOTAL_BUYS', 'TOTAL_SELLS', 'NB_DAYS_SINCE_FIRST_TRADE', 'AVG_NB_MINUTES_BETWEEN_TRADES']
X = nft_trades[features].values

pca = IncrementalPCA() 
X_pca = pca.fit_transform(X)

current_batch_size= 1000

mini_batch_kmeans = MiniBatchKMeans(n_clusters=5, batch_size=current_batch_size, random_state=42)
clusters = mini_batch_kmeans.fit_predict(X_pca)

sample_size =  50000 
score = silhouette_score(X_pca, clusters, sample_size=sample_size)
print(f"Batch size: {current_batch_size}, Silhouette Score: {score}")



centroids_pca = mini_batch_kmeans.cluster_centers_
centroids_original = pca.inverse_transform(centroids_pca)

centroids_df = pd.DataFrame(centroids_original, columns=features)


nft_trades['Cluster'] = clusters
print(nft_trades['Cluster'].value_counts())

nft_trades.to_csv('nft_traders_with_clusters.csv',index=False)


# Plotting as a heatmap
plt.figure(figsize=(12, 8))
sns.heatmap(centroids_df, annot=True, cmap="YlGnBu", fmt=".2f")
plt.title("Cluster Centroid Weights Heatmap")
plt.ylabel("Cluster")
plt.xticks(rotation=45, ha="right")
plt.tight_layout()
plt.show()
