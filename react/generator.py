import numpy
import random
from numpy.random import random_integers as rand

def maze(width=15, height=15, complexity=.75, density=.75):
    startingX = 1
    startingY = 1
    # Open the file where the maze is to be saved
    f = open("public/python-generated-maze.txt","w+")
    # First line is maze size
    f.write("%d %d\n" %(width+1, height+1))
    # Second line is starting point
    f.write("%d %d\n" %(startingX, startingY))
    # Only odd shapes
    shape = ((height // 2) * 2 + 1, (width // 2) * 2 + 1)
    # Adjust complexity and density relative to maze size
    complexity = int(complexity * (5 * (shape[0] + shape[1]))) # number of components
    density    = int(density * ((shape[0] // 2) * (shape[1] // 2))) # size of components
    # Build actual maze
    Z = numpy.zeros(shape, dtype=bool)
    # Fill borders
    Z[0, :] = Z[-1, :] = 1
    Z[:, 0] = Z[:, -1] = 1
    # Make aisles
    for i in range(density):
        x, y = rand(0, shape[1] // 2) * 2, rand(0, shape[0] // 2) * 2 # pick a random position
        Z[y, x] = 1
        for j in range(complexity):
            neighbours = []
            if x > 1:             neighbours.append((y, x - 2))
            if x < shape[1] - 2:  neighbours.append((y, x + 2))
            if y > 1:             neighbours.append((y - 2, x))
            if y < shape[0] - 2:  neighbours.append((y + 2, x))
            if len(neighbours):
                y_,x_ = neighbours[rand(0, len(neighbours) - 1)]
                if Z[y_, x_] == 0:
                    Z[y_, x_] = 1
                    Z[y_ + (y - y_) // 2, x_ + (x - x_) // 2] = 1
                    x, y = x_, y_
    # Third line is ending point
    # Empezar el finalX, finalY randomizado
    finalX = height - 1
    finalY = width - 1
    print("finalX %d, finalY %d" % (finalX, finalY))
    # while(Z[finalX, finalY] == 1):
    #     finalX = random.randint(0, height)
    #     finalY = random.randint(0, width)

    f.write("%d %d\n" %(finalX, finalY))
    for i in range(height + 1):
        for j in range(width + 1):
            if (j != width): f.write("%d " % Z[i, j])
            else: f.write("%d" % Z[i, j])
        f.write("\n")
    f.close()
    return Z

maze(20, 20);
