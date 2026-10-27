import numpy as np, pandas as pd
rng=np.random.default_rng(42)
# dim_date
d=pd.date_range("2023-01-01","2025-12-31")
dd=pd.DataFrame({"date_key":d.strftime("%Y%m%d").astype(int),"full_date":d.date,"year":d.year,"quarter":d.quarter,
 "month_num":d.month,"month_name":d.strftime("%b"),"week_of_year":d.isocalendar().week.values,"day_name":d.strftime("%a"),
 "is_weekend":(d.dayofweek>=5).astype(int)})
dd.to_csv("data/dim_date.csv",index=False)
# stores
stores=[("Mumbai","Maharashtra","West"),("Pune","Maharashtra","West"),("Nagpur","Maharashtra","West"),("Ahmedabad","Gujarat","West"),
("Delhi","Delhi","North"),("Gurgaon","Haryana","North"),("Jaipur","Rajasthan","North"),("Bengaluru","Karnataka","South"),
("Chennai","Tamil Nadu","South"),("Hyderabad","Telangana","South"),("Kolkata","West Bengal","East"),("Bhubaneswar","Odisha","East")]
ds=pd.DataFrame([(i+1,f"Store {c}",c,s,r,["Flagship","Standard","Standard","Mini"][i%4]) for i,(c,s,r) in enumerate(stores)],
 columns=["store_key","store_name","city","state","region","store_type"])
ds.to_csv("data/dim_store.csv",index=False)
# products
cats={"Electronics":["Earbuds","Smartwatch","Power Bank","Bluetooth Speaker","Webcam","Keyboard","Mouse","Phone Case"],
"Home & Kitchen":["Air Fryer","Mixer Grinder","Water Bottle","Lunch Box","Cookware Set","Table Lamp","Storage Jar","Kettle"],
"Fashion":["T-Shirt","Jeans","Hoodie","Sneakers","Backpack","Wallet","Cap","Socks Pack"],
"Beauty & Care":["Face Wash","Sunscreen","Shampoo","Perfume","Trimmer","Hair Dryer","Moisturizer","Lip Balm"],
"Sports & Fitness":["Yoga Mat","Dumbbell Set","Skipping Rope","Resistance Bands","Gym Gloves","Shaker Bottle","Football","Badminton Racket"]}
base={"Electronics":(900,3500),"Home & Kitchen":(300,3000),"Fashion":(250,2500),"Beauty & Care":(150,1800),"Sports & Fitness":(200,2500)}
rows=[];k=1
for c,items in cats.items():
    for it in items:
        p=int(rng.integers(*base[c]));rows.append((k,f"{it}",c,f"{c[:3].upper()}-{k:03d}",p,int(p*rng.uniform(.55,.75))));k+=1
dp=pd.DataFrame(rows,columns=["product_key","product_name","category","sku","unit_price","unit_cost"])
dp.to_csv("data/dim_product.csv",index=False)
# customers
N=3000
sd=pd.to_datetime("2021-06-01")+pd.to_timedelta(rng.integers(0,1650,N),unit="D")
dc=pd.DataFrame({"customer_key":range(1,N+1),"customer_name":[f"Customer {i:04d}" for i in range(1,N+1)],
"gender":rng.choice(["Male","Female"],N),"age_group":rng.choice(["18-24","25-34","35-44","45-54","55+"],N,p=[.18,.35,.25,.14,.08]),
"city":rng.choice(ds.city,N),"segment":rng.choice(["Consumer","Corporate","Home Office"],N,p=[.65,.2,.15]),"signup_date":sd.date})
dc.to_csv("data/dim_customer.csv",index=False)
# facts
M=30000
od=pd.to_datetime("2023-01-01")+pd.to_timedelta(rng.integers(0,1095,M),unit="D")
# seasonality: resample with weights
w=np.where(od.month.isin([10,11,12]),1.0,np.where(od.month.isin([1,2,3,4,5,6,7,8,9]),0.62,0.62))
keep=rng.random(M)<w; od=od[keep]; M=len(od)
cust=rng.choice(dc.customer_key,M,p=(lambda x:x/x.sum())(rng.pareto(2.2,N)+1))
# customer cannot buy before signup
su=dc.set_index("customer_key").signup_date
od=pd.Series([max(a,pd.Timestamp(su[c])) for a,c in zip(od,cust)])
od=od[od<="2025-12-31"]
M=len(od);cust=cust[:M]
prod=rng.choice(dp.product_key,M,p=(lambda x:x/x.sum())(rng.pareto(1.5,len(dp))+1))
store=rng.choice(ds.store_key,M,p=[.14,.12,.05,.08,.13,.07,.05,.12,.09,.08,.05,.02])
qty=rng.choice([1,2,3,4],M,p=[.6,.25,.1,.05])
price=dp.set_index("product_key").unit_price[prod].values; cost=dp.set_index("product_key").unit_cost[prod].values
disc=rng.choice([0,5,10,15,20],M,p=[.45,.2,.2,.1,.05])
sales=np.round(qty*price*(1-disc/100),2)
f=pd.DataFrame({"order_line_id":range(1,M+1),"order_id":[f"ORD{100000+i//2}" for i in range(M)],
"date_key":od.dt.strftime("%Y%m%d").astype(int),"customer_key":cust,"product_key":prod,"store_key":store,"quantity":qty,
"unit_price":price,"discount_pct":disc,"sales_amount":sales,"cost_amount":np.round(qty*cost,2),
"payment_mode":rng.choice(["UPI","Credit Card","Debit Card","Cash","Net Banking"],M,p=[.42,.22,.16,.12,.08]),
"return_flag":(rng.random(M)<.06).astype(int)})
f.to_csv("data/fact_sales.csv",index=False)
print(len(f))
# make multi-line orders consistent
f=pd.read_csv("data/fact_sales.csv")
oid=[];n=100000;i=0;rows=len(f)
while i<rows:
    size=rng.choice([1,2,3],p=[.55,.3,.15]);size=min(size,rows-i)
    for j in range(size):
        if j>0:
            for c in ["date_key","customer_key","store_key","payment_mode"]:
                f.loc[i+j,c]=f.loc[i,c]
        oid.append(f"ORD{n}")
    n+=1;i+=size
f["order_id"]=oid
f.to_csv("data/fact_sales.csv",index=False)
print(f.order_id.nunique())
