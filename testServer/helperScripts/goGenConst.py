consts_file = open('consts.txt', 'r')
const_val = 0

print("const (")

for line in consts_file:
    const = line[:-1]
    print(f"\t%s uint8 = %d" %(const, const_val))
    const_val += 1

print(")")
