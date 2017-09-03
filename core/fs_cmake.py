#coding:UTF-8
import os
import sys

def proj_tree(proj_path):
    tree_cmake, tree_makelists = [], []
    for root, dirs, files in os.walk(proj_path, True):
        for file in files:
            if file.endswith(r'.cmake'):
                tree_cmake.append(os.path.join(root,file))
            if file == 'CMakeLists.txt':
                tree_makelists.append(os.path.join(root,file))

    return tree_cmake, tree_makelists

if __name__ == "__main__":
    tree_cmake, tree_makefiles = proj_tree(sys.argv[1])
    for i in tree_cmake:
        print i
    for i in tree_makefiles:
        print i