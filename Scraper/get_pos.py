# -*- coding: utf-8 -*-
from bs4 import BeautifulSoup
import requests
import pandas as pd
import re

# df = pd.read_csv("Names-09.csv")

# print("Read complete")

url = "https://www.fifaindex.com"

def get_poss(endpoint):
    url_temp = url+endpoint
    print(url_temp)
    # continue

    try:
        page = requests.get(url_temp)
    except requests.exceptions.RequestException as e:  # This is the correct syntax
        print(e)
        return None
        
    html = page.content
    soup = BeautifulSoup(html,'lxml')

    regex = re.compile('badge badge-dark position*')
    # Nat = soup.find_all("span", {"class" : regex})
    # print(Nat)
    # continue
    group = soup.find_all("div", class_="card-body")
    final_pos = None
    for g in group:
        # p = g.findAll('p')
        z = g.find("span", {"class" : regex})
        if z != None:
            p = g.findAll('p')
            if p != None and "Position" in p[0].text and len(p) > 2:
                # print(z.text)
                if z.text != "Sub" and z.text != "Res":
                    return z.text
                else:
                    break

    for g in group:
        # p = g.findAll('p')
        z = g.find("span", {"class" : regex})
        if z != None:
            p = g.findAll('p')
            if p != None:
                for i in range(len(p)):
                    if "Preferred Positions" in p[i].text:
                        return z.text

    return None

if __name__ == "__main__":
    print(get_poss("/player/207716/abdullah-al-hafith/fifa16/"))
