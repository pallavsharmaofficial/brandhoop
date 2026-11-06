"""The starting phone list: 50 popular models in India plus two keypad phones.

Prices are LAUNCH prices in rupees reported by Indian news and price-list sites
(see docs/CREDITS.md). Where outlets disagreed, or nothing reliable was found,
the price is None and the app shows "Price on call". Nothing here is the shop's
price: every phone is marked call-for-best-price.

Each row: id, name, brand, launch ('Mon YYYY' or ''), variants [(label, price)],
highlights [(en, hi)], Wikimedia Commons search text, title words that must
appear in a matching file name.
"""
M = {'Jan': 'जनवरी', 'Feb': 'फ़रवरी', 'Mar': 'मार्च', 'Apr': 'अप्रैल', 'May': 'मई', 'Jun': 'जून',
     'Jul': 'जुलाई', 'Aug': 'अगस्त', 'Sep': 'सितंबर', 'Oct': 'अक्टूबर', 'Nov': 'नवंबर', 'Dec': 'दिसंबर'}

def hl(*pairs):
    return [(p, p) if isinstance(p, str) else p for p in pairs]

PHONES = [
 # ---- under 10,000
 ('redmi-a4-5g', 'Redmi A4 5G', 'Redmi', 'Nov 2024', [('Base model', 8499), ('6 GB + 128 GB', 9999)], [], 'Redmi A4 5G', ['a4']),
 ('poco-c75-5g', 'POCO C75 5G', 'POCO', 'Dec 2024', [('Base model', 7999)], [], 'POCO C75 5G', ['c75']),
 ('redmi-14c-5g', 'Redmi 14C 5G', 'Redmi', 'Jan 2025', [('4 GB + 64 GB', 9999), ('4 GB + 128 GB', 10999), ('6 GB + 128 GB', 11999)], [], 'Redmi 14C 5G', ['14c']),
 ('tecno-spark-30c-5g', 'Tecno Spark 30C 5G', 'Tecno', 'Oct 2024', [('4 GB + 64 GB', 9999), ('4 GB + 128 GB', 10499), ('8 GB + 128 GB', 12999)],
     hl(('MediaTek Dimensity 6300', 'MediaTek Dimensity 6300'), ('48 MP camera', '48 MP कैमरा')), 'Tecno Spark 30C', ['spark 30c', 'spark30c']),
 ('infinix-hot-60i-5g', 'Infinix Hot 60i 5G', 'Infinix', 'Aug 2025', [('4 GB + 128 GB', 9299)],
     hl(('6,000 mAh battery', '6,000 mAh बैटरी'), ('120 Hz display', '120 Hz डिस्प्ले'), ('MediaTek Dimensity 6400', 'MediaTek Dimensity 6400')), 'Infinix Hot 60i', ['hot 60i', 'hot60i']),
 ('samsung-galaxy-a06', 'Samsung Galaxy A06', 'Samsung', '', [('Standard', None)], [], 'Samsung Galaxy A06', ['a06']),
 ('motorola-g06-power', 'Motorola g06 Power', 'Motorola', '', [('Standard', None)], [], 'Motorola g06 power', ['g06']),
 # ---- 10,000 to 15,000
 ('oppo-a6x-5g', 'OPPO A6x 5G', 'OPPO', 'Dec 2025', [('4 GB + 64 GB', 12499), ('4 GB + 128 GB', 13499), ('6 GB + 128 GB', 14999)],
     hl(('6,500 mAh battery', '6,500 mAh बैटरी'), ('120 Hz display', '120 Hz डिस्प्ले'), ('MediaTek Dimensity 6300', 'MediaTek Dimensity 6300')), None, None),
 ('vivo-t4x-5g', 'vivo T4x 5G', 'vivo', 'Mar 2025', [('6 GB + 128 GB', 13999), ('8 GB + 128 GB', 14999), ('8 GB + 256 GB', 16999)],
     hl(('6,500 mAh battery', '6,500 mAh बैटरी'), ('MediaTek Dimensity 7300', 'MediaTek Dimensity 7300')), 'vivo T4x', ['t4x']),
 ('redmi-15-5g', 'Redmi 15 5G', 'Redmi', 'Aug 2025', [('6 GB + 128 GB', 14999), ('8 GB + 128 GB', 15999), ('8 GB + 256 GB', 16999)],
     hl(('7,000 mAh battery', '7,000 mAh बैटरी'), ('144 Hz display', '144 Hz डिस्प्ले'), ('Snapdragon 6s Gen 3', 'Snapdragon 6s Gen 3')), 'Redmi 15 5G', ['redmi 15 ', 'redmi 15.', 'redmi15 ']),
 ('poco-m7-plus-5g', 'POCO M7 Plus 5G', 'POCO', 'Aug 2025', [('6 GB + 128 GB', 13999)], hl(('Snapdragon 6s Gen 3', 'Snapdragon 6s Gen 3')), 'POCO M7 Plus', ['m7 plus']),
 ('iqoo-z10x-5g', 'iQOO Z10x 5G', 'iQOO', 'Apr 2025', [('6 GB + 128 GB', 13499), ('8 GB + 128 GB', 14999), ('8 GB + 256 GB', 16499)],
     hl(('MediaTek Dimensity 7300', 'MediaTek Dimensity 7300')), 'iQOO Z10x', ['z10x']),
 ('oppo-k13x-5g', 'OPPO K13x 5G', 'OPPO', 'Jun 2025', [('4 GB + 128 GB', 11999), ('6 GB + 128 GB', 12999), ('8 GB + 128 GB', 14999)],
     hl(('6,000 mAh battery', '6,000 mAh बैटरी'), ('50 MP camera', '50 MP कैमरा'), ('120 Hz display', '120 Hz डिस्प्ले')), 'OPPO K13x', ['k13x']),
 ('samsung-galaxy-m16-5g', 'Samsung Galaxy M16 5G', 'Samsung', '', [('Standard', None)], [], 'Samsung Galaxy M16', ['m16']),
 ('realme-p3x-5g', 'realme P3x 5G', 'realme', 'Feb 2025', [('6 GB + 128 GB', 13999), ('8 GB + 128 GB', 14999)], [], 'realme P3x', ['p3x']),
 ('poco-m7-pro-5g', 'POCO M7 Pro 5G', 'POCO', 'Dec 2024', [('Standard', 14999)], hl(('MediaTek Dimensity 7025 Ultra', 'MediaTek Dimensity 7025 Ultra'), ('AMOLED display', 'AMOLED डिस्प्ले')), 'POCO M7 Pro', ['m7 pro']),
 ('realme-narzo-80x-5g', 'realme Narzo 80x 5G', 'realme', 'Apr 2025', [('6 GB + 128 GB', 13999), ('8 GB + 128 GB', 14999)], hl(('MediaTek Dimensity 6400', 'MediaTek Dimensity 6400')), 'realme Narzo 80x', ['narzo 80x']),
 # ---- 15,000 to 25,000
 ('samsung-galaxy-m36-5g', 'Samsung Galaxy M36 5G', 'Samsung', 'Jun 2025', [('6 GB + 128 GB', 16499), ('8 GB + 128 GB', 17999), ('8 GB + 256 GB', 20999)],
     hl(('120 Hz sAMOLED display', '120 Hz sAMOLED डिस्प्ले'), ('50 MP triple camera', '50 MP ट्रिपल कैमरा'), ('5,000 mAh battery', '5,000 mAh बैटरी')), 'Galaxy M36', ['m36']),
 ('oppo-k13-5g', 'OPPO K13 5G', 'OPPO', 'Apr 2025', [('8 GB + 128 GB', 17999), ('8 GB + 256 GB', 19999)],
     hl(('7,000 mAh battery', '7,000 mAh बैटरी'), ('Snapdragon 6 Gen 4', 'Snapdragon 6 Gen 4')), 'OPPO K13 5G', ['k13 ', 'k13.', 'k13 5g']),
 ('redmi-note-14-5g', 'Redmi Note 14 5G', 'Redmi', 'Dec 2024', [('6 GB + 128 GB', 18999), ('8 GB + 128 GB', 19999), ('8 GB + 256 GB', 21999)], [], 'Redmi Note 14 5G', ['note 14']),
 ('realme-p4-5g', 'realme P4 5G', 'realme', 'Aug 2025', [('6 GB + 128 GB', 18499), ('8 GB + 128 GB', 19499), ('8 GB + 256 GB', 21499)],
     hl(('7,000 mAh battery', '7,000 mAh बैटरी'), ('144 Hz AMOLED display', '144 Hz AMOLED डिस्प्ले')), 'realme P4', ['p4 ', 'p4.']),
 ('iqoo-z10-5g', 'iQOO Z10 5G', 'iQOO', 'Apr 2025', [('8 GB + 128 GB', 21999), ('8 GB + 256 GB', 23999), ('12 GB + 256 GB', 25999)],
     hl(('Snapdragon 7s Gen 3', 'Snapdragon 7s Gen 3'), ('7,300 mAh battery', '7,300 mAh बैटरी'), ('90W fast charging', '90W फ़ास्ट चार्जिंग')), 'iQOO Z10', ['z10 ', 'z10.', 'z10 5g']),
 ('vivo-t4-5g', 'vivo T4 5G', 'vivo', 'Apr 2025', [('Base model', 21999)],
     hl(('Snapdragon 7s Gen 3', 'Snapdragon 7s Gen 3'), ('7,300 mAh battery', '7,300 mAh बैटरी'), ('90W fast charging', '90W फ़ास्ट चार्जिंग')), 'vivo T4 5G', ['t4 ', 't4.', 't4 5g']),
 ('redmi-note-15-5g', 'Redmi Note 15 5G', 'Redmi', 'Jan 2026', [('8 GB + 128 GB', 22999), ('8 GB + 256 GB', 24999)], [], 'Redmi Note 15 5G', ['note 15']),
 ('motorola-edge-60-fusion', 'Motorola Edge 60 Fusion', 'Motorola', 'Apr 2025', [('8 GB + 256 GB', 22999), ('12 GB + 256 GB', 24999)], [], 'Motorola Edge 60 Fusion', ['edge 60']),
 ('nothing-phone-3a', 'Nothing Phone (3a)', 'Nothing', 'Mar 2025', [('Base model', 24999)], [], 'Nothing Phone (3a)', ['phone (3a)', 'phone 3a', '3a']),
 ('oneplus-nord-ce5', 'OnePlus Nord CE5', 'OnePlus', 'Jul 2025', [('8 GB + 128 GB', 24999), ('8 GB + 256 GB', 26999), ('12 GB + 256 GB', 28999)],
     hl(('AMOLED display', 'AMOLED डिस्प्ले'), ('50 MP camera', '50 MP कैमरा'), ('Up to 7,100 mAh battery', '7,100 mAh तक की बैटरी')), 'OnePlus Nord CE5', ['ce5', 'ce 5']),
 ('redmi-note-14-pro-5g', 'Redmi Note 14 Pro 5G', 'Redmi', 'Dec 2024', [('8 GB + 128 GB', 24999), ('8 GB + 256 GB', 26999)], [], 'Redmi Note 14 Pro', ['note 14 pro']),
 ('realme-p4-power-5g', 'realme P4 Power 5G', 'realme', 'Feb 2026', [('8 GB + 128 GB', 25999), ('8 GB + 256 GB', 27999), ('12 GB + 256 GB', 30999)],
     hl(('10,001 mAh battery', '10,001 mAh बैटरी'), ('144 Hz display', '144 Hz डिस्प्ले')), 'realme P4 Power', ['p4 power']),
 ('iqoo-neo-10r-5g', 'iQOO Neo 10R 5G', 'iQOO', 'Mar 2025', [('Base model', 26999)], [], 'iQOO Neo 10R', ['neo 10r']),
 # ---- 25,000 to 50,000
 ('samsung-galaxy-m56-5g', 'Samsung Galaxy M56 5G', 'Samsung', 'Apr 2025', [('8 GB + 128 GB', 27999)], hl(('Exynos 1480 processor', 'Exynos 1480 प्रोसेसर')), 'Galaxy M56', ['m56']),
 ('poco-x7-pro-5g', 'POCO X7 Pro 5G', 'POCO', 'Jan 2025', [('8 GB + 256 GB', 27999), ('12 GB + 256 GB', 29999)],
     hl(('MediaTek Dimensity 8400 Ultra', 'MediaTek Dimensity 8400 Ultra'), ('6,500 mAh battery', '6,500 mAh बैटरी')), 'POCO X7 Pro', ['x7 pro']),
 ('redmi-note-15-pro-5g', 'Redmi Note 15 Pro 5G', 'Redmi', 'Jan 2026', [('8 GB + 128 GB', 29999), ('8 GB + 256 GB', 31999)], hl(('200 MP camera', '200 MP कैमरा')), 'Redmi Note 15 Pro', ['note 15 pro']),
 ('oneplus-nord-5', 'OnePlus Nord 5', 'OnePlus', 'Jul 2025', [('Base model', 31999)],
     hl(('Snapdragon 8s Gen 3', 'Snapdragon 8s Gen 3')), 'OnePlus Nord 5', ['nord 5']),
 ('samsung-galaxy-a36-5g', 'Samsung Galaxy A36 5G', 'Samsung', 'Mar 2025', [('8 GB + 128 GB', 32999), ('12 GB + 256 GB', 35999)],
     hl(('IP67 water and dust resistance', 'IP67 पानी और धूल से सुरक्षा'), ('6 years of OS updates', '6 साल के OS अपडेट')), 'Galaxy A36', ['a36']),
 ('oppo-reno-13-5g', 'OPPO Reno 13 5G', 'OPPO', 'Jan 2025', [('8 GB + 128 GB', 37999), ('8 GB + 256 GB', 39999), ('12 GB + 512 GB', 43999)], [], 'OPPO Reno 13', ['reno 13', 'reno13']),
 ('samsung-galaxy-a56-5g', 'Samsung Galaxy A56 5G', 'Samsung', 'Mar 2025', [('8 GB + 128 GB', 41999), ('8 GB + 256 GB', 44999), ('12 GB + 256 GB', 47999)],
     hl(('IP67 water and dust resistance', 'IP67 पानी और धूल से सुरक्षा'), ('6 years of OS updates', '6 साल के OS अपडेट')), 'Galaxy A56', ['a56']),
 ('oneplus-13r', 'OnePlus 13R', 'OnePlus', 'Jan 2025', [('12 GB + 256 GB', 42999), ('16 GB + 512 GB', 49999)], [], 'OnePlus 13R', ['13r']),
 ('google-pixel-9a', 'Google Pixel 9a', 'Google', 'Mar 2025', [('8 GB + 256 GB', 49999)], [], 'Google Pixel 9a', ['9a']),
 ('samsung-galaxy-a26-5g', 'Samsung Galaxy A26 5G', 'Samsung', '', [('Standard', None)], [], 'Galaxy A26', ['a26']),
 ('motorola-g96-5g', 'Motorola g96 5G', 'Motorola', '', [('Standard', None)], [], 'Motorola g96', ['g96']),
 ('poco-f7', 'POCO F7', 'POCO', '', [('Standard', None)], [], 'POCO F7', ['f7']),
 ('vivo-v50-5g', 'vivo V50 5G', 'vivo', '', [('Standard', None)], [], 'vivo V50', ['v50']),
 # ---- premium
 ('samsung-galaxy-s25-fe', 'Samsung Galaxy S25 FE', 'Samsung', 'Sep 2025', [('8 GB + 128 GB', 59999), ('8 GB + 256 GB', 65999), ('8 GB + 512 GB', 77999)],
     hl(('Exynos 2400 processor', 'Exynos 2400 प्रोसेसर'), ('50 MP camera', '50 MP कैमरा')), 'Galaxy S25 FE', ['s25 fe']),
 ('samsung-galaxy-s25', 'Samsung Galaxy S25', 'Samsung', '', [('Standard', None)], [], 'Galaxy S25', ['s25']),
 ('oneplus-13', 'OnePlus 13', 'OnePlus', '', [('Standard', None)], [], 'OnePlus 13', ['oneplus 13']),
 ('iphone-16', 'Apple iPhone 16', 'Apple', 'Sep 2024', [('128 GB', 79900)], [], 'iPhone 16', ['iphone 16']),
 ('iphone-16e', 'Apple iPhone 16e', 'Apple', '', [('Standard', None)], [], 'iPhone 16e', ['16e']),
 ('iphone-17', 'Apple iPhone 17', 'Apple', 'Sep 2025', [('256 GB', 82900), ('512 GB', 102900)],
     hl(('Lavender, Sage, Mist Blue, White and Black', 'लैवेंडर, सेज, मिस्ट ब्लू, सफ़ेद और काला')), 'iPhone 17', ['iphone 17']),
 ('iphone-17-pro', 'Apple iPhone 17 Pro', 'Apple', 'Sep 2025', [('256 GB', 134900)], [], 'iPhone 17 Pro', ['17 pro']),
 # ---- keypad phones
 ('nokia-105-classic', 'Nokia 105 Classic', 'Nokia', '', [('Single SIM', 999)], [], 'Nokia 105', ['nokia 105']),
 ('nokia-110-4g', 'Nokia 110 4G', 'Nokia', 'Jul 2021', [('Standard', 2799)], [], 'Nokia 110 4G', ['110']),
]
KEYPAD = {'nokia-105-classic', 'nokia-110-4g'}
