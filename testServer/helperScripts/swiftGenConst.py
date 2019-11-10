consts_file = open('consts.txt', 'r')
const_val = 0

for line in consts_file:
    const = line[:-1]
    print(f"let %s = %d" %(const, const_val))
    const_val += 1
