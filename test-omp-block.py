from subprocess import call
import time

# with open("./result/omp_block_result.txt", "w") as file:
#     file.flush()

# for t in range(2, 9):
#     for block_sz in [8, 16, 24, 32]:
#         for d in [960, 1920, 3840, 5760, 7680, 9600, 11520]:
#             call(["./bin/openmp_block.out", str(d), "100", str(t), str(block_sz)])
#             print(
#                 "Result when:  T="
#                 + str(t)
#                 + "   D="
#                 + str(d)
#                 + "   B="
#                 + str(block_sz),
#                 "\n",
#             )
#             time.sleep(1)

for t in range(8, 9):
    for block_sz in [240]:
        for d in [960, 1920, 3840, 5760, 7680, 9600, 11520]:
            call(["./bin/openmp_block.out", str(d), "100", str(t), str(block_sz)])
            print(
                "Result when:  T="
                + str(t)
                + "   D="
                + str(d)
                + "   B="
                + str(block_sz),
                "\n",
            )
            time.sleep(1)
