# herd

a small demo of a sheep-herding game. used as an opportunity to try out the LOVE2D engine for Lua & play with the "boids" flocking algorithm

sheep naturally flock according to a few influences:
- an attractive force toward the center of the flock
- a repulsive force to keep them separate from walls and each other (and the dog)
- a "conformity" force where they try to match each other's velocities

the algorithm & LOVE & Lua are great fun, the game concept not so much, so i'm leaving it here for now

![screenshot](https://github.com/DominicHolmes/herd/assets/12633255/0b664398-c34f-4435-b900-6cfdec81b0a4)

the algorithm runs pretty well (maintaining 60fps even with 500 or so entities pushing each other around) due to a simple optimization: sheep are bucketed so that they only consider their immediate neighbors. a naive implementation results in N^2 checks, which quickly bogs down the fps. using the buckets, a sheep must only check the surrounding 8 buckets (+ its own). within those buckets, only flockmates within the vision cone are considered. you can see the buckets and vision cone with the debug mode:

![vision cone](https://github.com/DominicHolmes/herd/assets/12633255/30878fad-0c18-411f-92fe-dfa42197de05)


to run:
- install [LOVE](https://love2d.org)
- alias your path to love (i.e. `alias love="/Applications/love.app/Contents/MacOS/love"`)
- run with `love .`
