"""Shop prices given by the owner, with specs checked against Indian news and price-list sites (see docs/CREDITS.md).

A model listed here shows the SHOP's price as a plain price (not call-for-best-price) with a "Shop price, updated <date>"
label. Models not listed keep the launch price and the call-for-best-price wording. `specs` use the keys the product
page knows (display, chip, battery, camera, os). Where sources disagreed, the spec is left out rather than guessed.
"""
UPDATED = ('26 Nov 2026', '26 नवंबर 2026')
# True: only phones listed below go into the shop. Older launch-price phones stay in phones.py and can be shown again by setting this to False.
ONLY_SHOP_PHONES = True

DATA = {
 'oppo-a6x-5g': dict(
    prices=[('4 GB + 64 GB', 19999), ('4 GB + 128 GB', 23999), ('6 GB + 128 GB', 26999)],
    highlights=[('6,500 mAh battery', '6,500 mAh बैटरी'), ('120 Hz display', '120 Hz डिस्प्ले'), ('45W fast charger in the box', 'बॉक्स में 45W फ़ास्ट चार्जर'), ('MediaTek Dimensity 6300', 'MediaTek Dimensity 6300')],
    specs={'display': 'About 6.7-inch HD+ LCD, 120 Hz', 'chip': 'MediaTek Dimensity 6300', 'battery': '6,500 mAh, 45W SUPERVOOC charging', 'camera': '13 MP rear camera'}),
 'oppo-k14x-5g': dict(
    prices=[('4 GB + 64 GB', 18999), ('4 GB + 128 GB', 21999), ('6 GB + 128 GB', 24999)],
    highlights=[('6,500 mAh battery', '6,500 mAh बैटरी'), ('45W SUPERVOOC charging', '45W SUPERVOOC चार्जिंग'), ('120 Hz display', '120 Hz डिस्प्ले'), ('50 MP camera', '50 MP कैमरा'), ('IP64 dust and splash protection', 'IP64 धूल और छींटों से सुरक्षा')],
    specs={'display': '6.75-inch HD+ LCD, 120 Hz, up to 1,125 nits', 'chip': 'MediaTek Dimensity 6300', 'battery': '6,500 mAh, 45W SUPERVOOC charging', 'camera': '50 MP rear, 5 MP front'}),
 'oppo-k14-5g': dict(
    prices=[('6 GB + 128 GB', 25999)],
    highlights=[('7,000 mAh battery', '7,000 mAh बैटरी'), ('45W SUPERVOOC charging', '45W SUPERVOOC चार्जिंग'), ('IP66 / IP68 / IP69 water and dust protection', 'IP66 / IP68 / IP69 पानी और धूल से सुरक्षा'), ('120 Hz display', '120 Hz डिस्प्ले')],
    specs={'display': '6.75-inch LCD, 120 Hz, up to 1,125 nits', 'chip': 'MediaTek Dimensity 6300', 'battery': '7,000 mAh, 45W SUPERVOOC, reverse charging', 'camera': '50 MP + 2 MP rear, 8 MP front', 'os': 'ColorOS 15 (Android 15)'}),
 'oppo-a6-5g': dict(
    prices=[('6 GB + 128 GB', 31999), ('6 GB + 256 GB', 33999)],
    highlights=[('7,000 mAh battery', '7,000 mAh बैटरी'), ('45W SUPERVOOC charging', '45W SUPERVOOC चार्जिंग'), ('IP66 / IP68 / IP69 water and dust protection', 'IP66 / IP68 / IP69 पानी और धूल से सुरक्षा'), ('50 MP camera', '50 MP कैमरा'), ('Side fingerprint sensor', 'साइड फ़िंगरप्रिंट सेंसर')],
    specs={'display': '6.75-inch HD+ LCD, 120 Hz', 'chip': 'MediaTek Dimensity 6300', 'battery': '7,000 mAh, 45W SUPERVOOC charging', 'camera': '50 MP + 2 MP rear, 8 MP front', 'os': 'ColorOS 15 (Android 15)'}),
 'oppo-a6s-5g': dict(
    prices=[('128 GB', 27999)],
    highlights=[('6,500 mAh battery', '6,500 mAh बैटरी'), ('45W SUPERVOOC charging', '45W SUPERVOOC चार्जिंग'), ('120 Hz display', '120 Hz डिस्प्ले'), ('50 MP camera', '50 MP कैमरा')],
    specs={'display': '6.75-inch HD+ LCD, 120 Hz, up to 1,125 nits', 'chip': 'MediaTek Dimensity 6300', 'battery': '6,500 mAh, 45W SUPERVOOC charging', 'camera': '50 MP + 2 MP rear, 5 MP front'}),
 'oppo-f35-5g': dict(
    prices=[('6 GB + 128 GB', 38999), ('8 GB + 128 GB', 42999)],
    highlights=[('8,000 mAh battery', '8,000 mAh बैटरी'), ('80W fast charging', '80W फ़ास्ट चार्जिंग'), ('50 MP front camera', '50 MP फ्रंट कैमरा'), ('IP69K water and dust protection', 'IP69K पानी और धूल से सुरक्षा')],
    specs={'display': 'AMOLED display', 'battery': '8,000 mAh, 80W SUPERVOOC charging', 'camera': '50 MP front camera', 'os': 'ColorOS 17'}),
 'oppo-f35-pro-5g': dict(
    prices=[('6 GB + 128 GB', 45999), ('8 GB + 128 GB', 49999), ('8 GB + 256 GB', 54999)],
    highlights=[('8,000 mAh battery', '8,000 mAh बैटरी'), ('80W fast charging', '80W फ़ास्ट चार्जिंग'), ('6.78-inch Full HD+ AMOLED', '6.78-इंच Full HD+ AMOLED'), ('50 MP front camera', '50 MP फ्रंट कैमरा'), ('IP69K water and dust protection', 'IP69K पानी और धूल से सुरक्षा')],
    specs={'display': '6.78-inch Full HD+ AMOLED', 'battery': '8,000 mAh, 80W SUPERVOOC charging', 'camera': '50 MP + 2 MP rear, 50 MP front', 'os': 'ColorOS 17'}),
 'oppo-reno-16c-5g': dict(
    prices=[('8 GB + 128 GB', 52999), ('8 GB + 256 GB', 57999), ('12 GB + 256 GB', 62999)],
    highlights=[('6.57-inch AMOLED, 120 Hz', '6.57-इंच AMOLED, 120 Hz'), ('MediaTek Dimensity 7300', 'MediaTek Dimensity 7300'), ('50 MP triple rear camera', '50 MP ट्रिपल रियर कैमरा'), ('50 MP front camera', '50 MP फ्रंट कैमरा')],
    specs={'display': '6.57-inch AMOLED, 120 Hz', 'chip': 'MediaTek Dimensity 7300', 'camera': '50 MP + 50 MP + 8 MP rear, 50 MP front', 'os': 'ColorOS 16'}),
 'oppo-reno-16-5g': dict(
    prices=[('8 GB + 128 GB', 65999), ('8 GB + 256 GB', 72999), ('12 GB + 256 GB', 79999)],
    highlights=[('6.32-inch 1.5K AMOLED, 120 Hz', '6.32-इंच 1.5K AMOLED, 120 Hz'), ('Snapdragon 7 Gen 4', 'Snapdragon 7 Gen 4'), ('6,700 mAh battery', '6,700 mAh बैटरी'), ('50 MP main and 50 MP front camera', '50 MP मुख्य और 50 MP फ्रंट कैमरा'), ('IP68 / IP69 water and dust protection', 'IP68 / IP69 पानी और धूल से सुरक्षा')],
    specs={'display': '6.32-inch 1.5K AMOLED, 120 Hz', 'chip': 'Snapdragon 7 Gen 4', 'battery': '6,700 mAh, 80W SUPERVOOC charging', 'camera': '50 MP main (LYT-600), 50 MP front', 'os': 'ColorOS 16'}),
}
