import re
import openpyxl

def get_key(val, my_dict):
	for key, value in my_dict.items():
		if val == value:
			return key
	return None

def joinSameIds(my_dict):
	for k in my_dict:
		print(str(k) + '->')
		print(my_dict[k])
		print('----------')

def writeLista(f, auxDict):
	lista = []
	for i in auxDict:
		if auxDict[i] != 0:
			lista.append((i,auxDict[i]))
	f.write(str(lista))

def writeAdj(f,key,ruasIDID):
	if key in ruasIDID:
		if len(ruasIDID[key]) > 1:
			idAdj1 = int(ruasIDID[key][0])
			f.write('aresta('+key+','+str(idAdj1)+'),\n')
			idAdj2 = int(ruasIDID[key][1])
			f.write('aresta('+key+','+str(idAdj2)+'),\n')
		else:
			idAdj1 = int(ruasIDID[key][0])
			f.write('aresta('+key+','+str(idAdj1)+'),\n')

def writeGrafo(lixosID,ruasIDID):
	f = open("grafo.pl", "w")

	f.write('g2(grafo(')
	lista = list(lixosID.keys())
	for i in range(0, len(lista)):
		lista[i] = int(lista[i])
	f.write(str(lista)+ ',\n[')

	lastKey = list(lixosID.keys())[0]
	lastOne = list(lixosID.keys())[-1]
	writeAdj(f,lastKey,ruasIDID)
	for key in lixosID:
		if lastKey == key:
			pass
		else:
			if lastOne == key:
				writeAdj(f,key,ruasIDID)
				f.write('aresta('+lastKey+','+key+')])).\n')
			else:
				f.write('aresta('+lastKey+','+key+'),\n')
				writeAdj(f,key,ruasIDID)
				lastKey = key 


def main():
	f = openpyxl.load_workbook(filename='dataset.xlsx', data_only=True)

	mDict = {}
	ruasAdj = {}
	ruasIDName = {}
	ruasIDID = {}
	lixosID = {}

	sheet = f["Folha1"]
	for row in sheet.iter_rows():
		a = []
		for cell in row:
			a.append(cell.value)
		mDict[a[2]] = a
		num = re.search(r'\d+',a[4])
		nomeRua = re.search(r': ([-0-9A-zÀ-ú ]*),? ',a[4])
		if num:
			idr = num.group(0)
			if idr in ruasIDName:
				pass
			else:
				ruasIDName[idr] = nomeRua.group(1)
			ruasP = re.search(r':(?:.*): ([,()0-9A-zÀ-ú -]*(?:\([,0-9A-zÀ-ú -]*\))? - [0-9A-zÀ-ú -]*(?:\([,0-9A-zÀ-ú -]*\))?)',a[4])
			if (ruasP and ruasP.group(1)):
				arrayRuasAdj = []
				strs = ruasP.group(1).split(' - ')
				arrayRuasAdj.append(strs[0])
				arrayRuasAdj.append(strs[1])
				ruasAdj[idr] = arrayRuasAdj 
	for key in ruasAdj:
		strK1 = re.search(r'([0-9A-zÀ-ú -]*) \(',ruasAdj[key][0])
		if strK1 and strK1.group(1):
				strK1 = strK1.group(1)
		else:
			strK1 = ruasAdj[key][0]

		strK2 = re.search(r'([0-9A-zÀ-ú -]*) \(',ruasAdj[key][1])
		if strK2 and strK2.group(1):
				strK2 = strK2.group(1)
		else:
			strK2 = ruasAdj[key][1]
				
		k1 = get_key(strK1,ruasIDName)
		k2 = get_key(strK2,ruasIDName)

		add = []
		if k1:
			add.append(k1)
		if k2:
			add.append(k2)
		if add != []:
			ruasIDID[key] = add

	f = open("kb.pl", "w")

	fstRE = mDict[list(mDict.keys())[1]][4]
	fstKey = re.search(r'\d+',fstRE)
	idPR = fstKey.group(0)
	lastKey = list(mDict.keys())[-1]
	lixos = {'Lixos':0,'Papel e Cartão':0,'Embalagens':0,'Vidro':0,'Organicos':0}
	for k in mDict:
		if k == 'OBJECTID':
			pass
		else:
			strR = str(mDict[k][4])
			num = re.search(r'\d+', strR)
			if num.group(0) != idPR:
				lixosID[idPR] = lixos
				lixos = {'Lixos':0,'Papel e Cartão':0,'Embalagens':0,'Vidro':0,'Organicos':0}
				lixos[mDict[k][5]] += mDict[k][9]
			else:
				lixos[mDict[k][5]] += mDict[k][9]
				if k == lastKey:
					lixosID[idPR] = lixos
			idPR = num.group(0)

	for k in mDict:
		if k == 'OBJECTID':
			pass
		else:
			strR = str(mDict[k][4])
			num = re.search(r'\d+', strR)
			print
			if num.group(0) != idPR:
				f.write('pontoRecolha(' + str(mDict[k][0]) + ','
				+ str(mDict[k][1])+',' +str(mDict[k][2]) + ',\''+
				str(mDict[k][3])+'\','+ str(num.group(0)) +',\'' + str(mDict[k][4]) + '\',')
				auxDict = lixosID[num.group(0)]
				writeLista(f, auxDict)
				f.write(').\n')
			else:
				pass
			idPR = num.group(0)
	f.close()

	writeGrafo(lixosID, ruasIDID)

main()