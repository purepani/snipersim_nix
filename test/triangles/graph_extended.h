#ifndef GRAPH_EXTENDED_H_
#define GRAPH_EXTENDED_H_
#include "graph.h"
#include <vector>
#include <algorithm>

template <typename NodeID_, typename DestID_, bool MakeInverse>
std::vector<DestID_>
FindCommonNeighborIDsNoConstraints(const CSRGraph<NodeID_, DestID_, MakeInverse>& graph,
                                   NodeID_ v1,
                                   NodeID_ v2) {
  std::vector<DestID_> common_neighbors;

  std::vector<DestID_> v1_neighbors;
  v1_neighbors.reserve(graph.out_degree(v1));
  for (auto n : graph.out_neigh(v1))
    v1_neighbors.push_back(n);

  std::vector<DestID_> v2_neighbors;
  v2_neighbors.reserve(graph.out_degree(v2));
  for (auto n : graph.out_neigh(v2))
    v2_neighbors.push_back(n);

  std::sort(v1_neighbors.begin(), v1_neighbors.end());
  std::sort(v2_neighbors.begin(), v2_neighbors.end());

  size_t i = 0, j = 0;
  while (i < v1_neighbors.size() && j < v2_neighbors.size()) {
    if (v1_neighbors[i] < v2_neighbors[j]) {
      i++;
    } else if (v1_neighbors[i] > v2_neighbors[j]) {
      j++;
    } else {
      common_neighbors.push_back(v1_neighbors[i]);
      i++;
      j++;
    }
  }

  return common_neighbors;
}
#endif  // GRAPH_EXTENDED_H_
