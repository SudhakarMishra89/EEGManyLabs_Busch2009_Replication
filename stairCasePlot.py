import os
import pdb
import pandas as pd
import matplotlib.pyplot as plt

# stairCaseRes = pd.read_excel('staircase.xls')
stairCaseRes = pd.read_csv('Pilot02S01M27.csv')

leftVal = stairCaseRes[(stairCaseRes['Flash']==1) & (stairCaseRes['Cue']==1)]
leftIVal = stairCaseRes[(stairCaseRes['Flash']==2) & (stairCaseRes['Cue']==1)]
rightVal = stairCaseRes[(stairCaseRes['Flash']==2) & (stairCaseRes['Cue']==2)]
rightIVal = stairCaseRes[(stairCaseRes['Flash']==1) & (stairCaseRes['Cue']==2)]

print(leftVal.iloc[:,[0, 1, 5, 11]])
print(leftIVal.iloc[:,[0, 1, 5, 17]])
print(rightVal.iloc[:,[0, 1, 5, 13]])
print(rightIVal.iloc[:,[0, 1, 5, 15]])
#pdb.set_trace()
#print(leftVal)
plt.plot(leftVal['Lumin.'].values, 'r.')
plt.savefig('leftVal.png')
plt.close()
plt.plot(leftIVal['Lumin.'].values, 'r.')
plt.savefig('leftIVal.png')
plt.close()
plt.plot(rightVal['Lumin.'].values, 'r.')
plt.savefig('rightVal.png')
plt.close()
plt.plot(rightIVal['Lumin.'].values, 'r.')
plt.savefig('rightIVal.png')
plt.close()