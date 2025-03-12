#include <iostream>
#include <vector>

#include "benchmark.h"
#include "bitmap.h"
#include "builder.h"
#include "command_line.h"
#include "graph.h"
#include "graph_extended.h"
#include "platform_atomics.h"
#include "pvector.h"
#include "timer.h"

#include "sim_api.h"
#include <omp.h>
#define NUM_THREADS 16
#define SNIPERSIM_ 1

unsigned long long FindNumTriangles(const Graph& g)
{
    unsigned long long num_triangles = 0;

#ifdef SNIPERSIM_
    SimRoiStart();
#else
    Timer t_tri;
    t_tri.Start();
#endif

#pragma omp parallel for reduction(+ : num_triangles) schedule(dynamic, NUM_THREADS)
    for (NodeID u0 = 0; u0 < g.num_nodes(); ++u0) {
        for (NodeID u1 : g.out_neigh(u0)) {
            if (u1 >= u0) {
                break;
            }

            std::vector<NodeID> u0_u1_neigh_intersection = FindCommonNeighborIDsNoConstraints(g, u0, u1);

            for (NodeID u2 : u0_u1_neigh_intersection) {
                if (u2 >= u1) {
                    // counter++;
                    break;
                }
                num_triangles++;
            }
        }
    }
#ifdef SNIPERSIM_
    SimRoiEnd();
#else
    t_tri.Stop();
    PrintStep("Triangle computation time (s):", t_tri.Seconds());
#endif

    return num_triangles;
}

int main(int argc, char* argv[])
{

    omp_set_num_threads(NUM_THREADS);
    printf("NUM Threads: %d\n", NUM_THREADS);

    CLApp cli(argc, argv, "gpm-triangle");

    if (!cli.ParseArgs())
        return -1;

    Builder b(cli);
    Graph g = b.MakeGraph();
    g.PrintStats();

    unsigned long long num_triangles = 0;
    num_triangles = FindNumTriangles(g);

    std::cout << "Number of triangles: " << num_triangles << std::endl;

    return 0;
}
