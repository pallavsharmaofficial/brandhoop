"""Starting accessories list: the kinds of items a mobile shop sells.

These are item TYPES, not branded products, so none carries a price: the app
shows "Price on call" and asks the customer for their phone model. The photo is
a free-licence illustration of that kind of item (key into acc_images.json), or
None where no suitable photo exists, in which case the app draws one.

Row: id, English name, Hindi name, category, photo key, needs a model/fit.
"""
ACC = [
 # ---- earphones and headphones
 ('acc-earphones-wired', 'Wired Earphones with Mic (3.5 mm)', 'माइक वाले तार वाले ईयरफ़ोन (3.5 mm)', 'earphones', 'wired', False),
 ('acc-earphones-typec', 'Wired Earphones (Type-C)', 'टाइप-C वाले तार वाले ईयरफ़ोन', 'earphones', 'wired', False),
 ('acc-neckband', 'Bluetooth Neckband Earphones', 'ब्लूटूथ नेकबैंड ईयरफ़ोन', 'earphones', None, False),
 ('acc-tws-earbuds', 'True Wireless Earbuds (TWS)', 'ट्रू वायरलेस ईयरबड्स', 'earphones', 'tws', False),
 ('acc-gaming-earbuds', 'Gaming Earbuds (low latency)', 'गेमिंग ईयरबड्स (कम लेटेंसी)', 'earphones', 'tws', False),
 ('acc-headphones-bluetooth', 'Bluetooth Over-ear Headphones', 'ब्लूटूथ ओवर-ईयर हेडफ़ोन', 'earphones', 'hp_bt', False),
 ('acc-headphones-wired', 'Wired Headphones with Mic', 'माइक वाले तार वाले हेडफ़ोन', 'earphones', 'hp_wired', False),
 # ---- chargers
 ('acc-charger-12w', '12W Charger (USB-A)', '12W चार्जर (USB-A)', 'charger', 'wall', False),
 ('acc-charger-20w', '20W Fast Charger (Type-C)', '20W फ़ास्ट चार्जर (टाइप-C)', 'charger', 'wall', False),
 ('acc-charger-33w', '33W Fast Charger', '33W फ़ास्ट चार्जर', 'charger', 'wall', False),
 ('acc-charger-65w', '65W GaN Fast Charger (phone and laptop)', '65W GaN फ़ास्ट चार्जर (फ़ोन और लैपटॉप)', 'charger', 'wall', False),
 ('acc-charger-combo', 'Fast Charger with Cable (combo)', 'केबल के साथ फ़ास्ट चार्जर (कॉम्बो)', 'charger', 'wall', False),
 ('acc-charger-car', 'Car Charger (dual port)', 'कार चार्जर (डुअल पोर्ट)', 'charger', None, False),
 ('acc-charger-wireless', 'Wireless Charger (15W)', 'वायरलेस चार्जर (15W)', 'charger', 'wireless', False),
 # ---- cables and adapters
 ('acc-cable-typec-typec', 'Type-C to Type-C Cable', 'टाइप-C से टाइप-C केबल', 'cable', 'cable', False),
 ('acc-cable-usb-typec', 'USB to Type-C Cable', 'USB से टाइप-C केबल', 'cable', 'cable', False),
 ('acc-cable-micro-usb', 'USB to Micro-USB Cable', 'USB से माइक्रो-USB केबल', 'cable', 'cable', False),
 ('acc-cable-lightning', 'USB to Lightning Cable (iPhone)', 'USB से लाइटनिंग केबल (iPhone)', 'cable', 'cable', False),
 ('acc-cable-typec-lightning', 'Type-C to Lightning Cable (iPhone)', 'टाइप-C से लाइटनिंग केबल (iPhone)', 'cable', 'cable', False),
 ('acc-cable-3in1', '3-in-1 Charging Cable', '3-इन-1 चार्जिंग केबल', 'cable', 'cable', False),
 ('acc-otg-adapter', 'OTG Adapter (Type-C / Micro-USB)', 'OTG एडाप्टर (टाइप-C / माइक्रो-USB)', 'cable', None, False),
 ('acc-aux-cable', 'AUX Cable (3.5 mm)', 'AUX केबल (3.5 mm)', 'cable', None, False),
 # ---- power banks
 ('acc-powerbank-5000', 'Pocket Power Bank 5000 mAh', 'पॉकेट पावर बैंक 5000 mAh', 'powerBank', 'powerbank', False),
 ('acc-powerbank-10000', 'Power Bank 10000 mAh', 'पावर बैंक 10000 mAh', 'powerBank', 'powerbank', False),
 ('acc-powerbank-20000', 'Power Bank 20000 mAh', 'पावर बैंक 20000 mAh', 'powerBank', 'powerbank', False),
 ('acc-powerbank-20000-fast', 'Power Bank 20000 mAh Fast Charging (22.5W)', 'पावर बैंक 20000 mAh फ़ास्ट चार्जिंग (22.5W)', 'powerBank', 'powerbank', False),
 # ---- cases and covers
 ('acc-case-silicone', 'Silicone Back Cover', 'सिलिकॉन बैक कवर', 'caseCover', None, True),
 ('acc-case-transparent', 'Transparent Back Cover', 'ट्रांसपेरेंट बैक कवर', 'caseCover', 'case_clear', True),
 ('acc-case-hard', 'Hard Case with Camera Protection', 'कैमरा सुरक्षा वाला हार्ड केस', 'caseCover', None, True),
 ('acc-case-flip', 'Flip Cover', 'फ़्लिप कवर', 'caseCover', None, True),
 # ---- screen guards
 ('acc-glass-tempered', 'Tempered Glass Screen Guard', 'टेम्पर्ड ग्लास स्क्रीन गार्ड', 'screenGuard', 'glass', True),
 ('acc-glass-fullcover', 'Full-coverage 9D Tempered Glass', 'फुल-कवरेज 9D टेम्पर्ड ग्लास', 'screenGuard', 'glass', True),
 ('acc-glass-privacy', 'Privacy Tempered Glass', 'प्राइवेसी टेम्पर्ड ग्लास', 'screenGuard', 'glass', True),
 ('acc-glass-matte', 'Matte Gaming Tempered Glass', 'मैट गेमिंग टेम्पर्ड ग्लास', 'screenGuard', 'glass', True),
 ('acc-camera-protector', 'Camera Lens Protector', 'कैमरा लेंस प्रोटेक्टर', 'screenGuard', None, True),
 ('acc-hydrogel-film', 'Hydrogel Screen Film', 'हाइड्रोजेल स्क्रीन फ़िल्म', 'screenGuard', None, True),
 # ---- watches and bands
 ('acc-smartwatch', 'Smartwatch (Bluetooth calling)', 'स्मार्टवॉच (ब्लूटूथ कॉलिंग)', 'smartwatch', 'smartwatch', False),
 ('acc-fitness-band', 'Fitness Band', 'फ़िटनेस बैंड', 'smartwatch', 'band', False),
 # ---- speakers
 ('acc-speaker-bluetooth', 'Portable Bluetooth Speaker', 'पोर्टेबल ब्लूटूथ स्पीकर', 'speaker', 'speaker', False),
 ('acc-soundbar', 'Bluetooth Soundbar', 'ब्लूटूथ साउंडबार', 'speaker', 'speaker', False),
 # ---- memory and storage
 ('acc-microsd-64', 'microSD Card 64 GB', 'माइक्रोSD कार्ड 64 GB', 'memory', 'memory', False),
 ('acc-microsd-128', 'microSD Card 128 GB', 'माइक्रोSD कार्ड 128 GB', 'memory', 'memory', False),
 ('acc-microsd-256', 'microSD Card 256 GB', 'माइक्रोSD कार्ड 256 GB', 'memory', 'memory', False),
 ('acc-pendrive-32', 'Pen Drive 32 GB', 'पेन ड्राइव 32 GB', 'memory', 'pendrive', False),
 ('acc-pendrive-64', 'Pen Drive 64 GB', 'पेन ड्राइव 64 GB', 'memory', 'pendrive', False),
 ('acc-pendrive-typec', 'Dual Pen Drive (Type-C + USB)', 'डुअल पेन ड्राइव (टाइप-C + USB)', 'memory', 'pendrive', False),
 ('acc-card-reader', 'Memory Card Reader', 'मेमोरी कार्ड रीडर', 'memory', None, False),
 # ---- stands, holders, tripods
 ('acc-stand-desk', 'Mobile Stand (desk)', 'मोबाइल स्टैंड (डेस्क)', 'holder', 'stand', False),
 ('acc-holder-car', 'Car Mobile Holder', 'कार मोबाइल होल्डर', 'holder', 'carholder', False),
 ('acc-tripod-tall', 'Mobile Tripod (tall)', 'मोबाइल ट्राइपॉड (लंबा)', 'holder', 'tripod_tall', False),
 ('acc-tripod-flexible', 'Flexible Mobile Tripod', 'फ़्लेक्सिबल मोबाइल ट्राइपॉड', 'holder', 'tripod_flex', False),
 ('acc-selfie-stick', 'Selfie Stick', 'सेल्फ़ी स्टिक', 'holder', None, False),
 ('acc-ring-light', 'Ring Light with Phone Holder', 'फ़ोन होल्डर वाली रिंग लाइट', 'holder', None, False),
]
