consts_file = open('consts.txt', 'r')
const_val = 0
gen_str = 'const (\n'

for line in consts_file:
    const = line[:-1]
    gen_str += '\t%s uint8 = %d\n' %(const, const_val)
    const_val += 1

gen_str += ')\n'
print(gen_str, end = '')
file = open('consts_ref.go', 'w+')
file.write(gen_str)
file.close()
