# -*- coding: utf-8 -*-
from bs4 import BeautifulSoup
import requests
import pandas as pd

url = "https://www.fifaindex.com"
# proxies = {
#   'http': 'http://10.4.22.5:3128',
#   'https': 'https://10.4.22.5:3128',
# }

# year = ['09', '10', '11', '12', '13', '14', '15', '16']
year = ['12', '13']

for y in year:
	temp_df = pd.read_csv(f'Names-{y}.csv')
	page = requests.get(f'{url}/players/fifa{y}')

	html = page.content
	soup = BeautifulSoup(html,'lxml')

	# print(soup)
	right_table=soup.find('table', class_='table table-striped table-players')

	A=temp_df["Name"].tolist()
	B=temp_df["url"].tolist()

	# for row in right_table.findAll("tr"):
	# 	cells = row.find("td")
	# 	if(cells!=None):
	# 		a = cells.find("a")
	# 		if(a!=None):
	# 			A.append(a["title"])
	# 			B.append(a["href"])

	# temp_df=pd.DataFrame({'Name':A, 'url' : B})
	# print(temp_df)

	for i in range(250,1000):
		url_temp = f'{url}/players/fifa{y}/?page={i}'
		print(i, url_temp)

		while(True):
			print("Getting page "+str(i))
			try:
				page = requests.get(url_temp)
			except requests.exceptions.RequestException as e:  # This is the correct syntax
				print(e)
				continue
			break

		html = page.content
		soup = BeautifulSoup(html,'lxml')
		if soup == None:
			break
		right_table=soup.find('table', class_='table table-striped table-players')

		if right_table == None:
			break
		# print(right_table)
		# print("WTF")

		for row in right_table.findAll("tr"):
			cells = row.find("td")
			if(cells!=None):
				a = cells.find("a")
				if(a!=None):
					A.append(a["title"])
					B.append(a["href"])
		df=pd.DataFrame({'Name':A, 'url' : B})
		# print(df)
	df.to_csv(f'Names-{y}-new.csv', index = False, encoding = 'utf-8')

