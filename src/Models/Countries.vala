/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2022 Louis Brauer <louis@brauer.family>
 * SPDX-FileCopyrightText: Copyright © 2026 technosf <https://github.com/technosf>
 */

using Gee;

/*
    ISO 3166-1 alpha-2 codes are two-letter country codes defined in ISO 3166-1, 
    part of the ISO 3166 standard[1] published by the 
    International Organization for Standardization (ISO), 
    to represent countries, dependent territories, 
    and special areas of geographical interest.
*/
namespace Tuner.Models {

    public class Countries {
        
        public static HashMap<string, string> _map = null;

        public static HashMap<string, string> map {
            get {
                if (_map == null) {
                    _map = new HashMap<string, string> ();
                    _map["AF"] = NC_("Countries","Afghanistan");
                    _map["AX"] = NC_("Countries","Aland Islands");
                    _map["AL"] = NC_("Countries","Albania");
                    _map["DZ"] = NC_("Countries","Algeria");
                    _map["AS"] = NC_("Countries","American Samoa");
                    _map["AD"] = NC_("Countries","Andorra");
                    _map["AO"] = NC_("Countries","Angola");
                    _map["AI"] = NC_("Countries","Anguilla");
                    _map["AQ"] = NC_("Countries","Antarctica");
                    _map["AG"] = NC_("Countries","Antigua and Barbuda");
                    _map["AR"] = NC_("Countries","Argentina");
                    _map["AM"] = NC_("Countries","Armenia");
                    _map["AW"] = NC_("Countries","Aruba");
                    _map["AU"] = NC_("Countries","Australia");
                    _map["AT"] = NC_("Countries","Austria");
                    _map["AZ"] = NC_("Countries","Azerbaijan");
                    _map["BS"] = NC_("Countries","Bahamas");
                    _map["BH"] = NC_("Countries","Bahrain");
                    _map["BD"] = NC_("Countries","Bangladesh");
                    _map["BB"] = NC_("Countries","Barbados");
                    _map["BY"] = NC_("Countries","Belarus");
                    _map["BE"] = NC_("Countries","Belgium");
                    _map["BZ"] = NC_("Countries","Belize");
                    _map["BJ"] = NC_("Countries","Benin");
                    _map["BM"] = NC_("Countries","Bermuda");
                    _map["BT"] = NC_("Countries","Bhutan");
                    _map["BO"] = NC_("Countries","Bolivia");
                    _map["BQ"] = NC_("Countries","Bonaire, Sint Eustatius and Saba");
                    _map["BA"] = NC_("Countries","Bosnia and Herzegovina");
                    _map["BW"] = NC_("Countries","Botswana");
                    _map["BV"] = NC_("Countries","Bouvet Island");
                    _map["BR"] = NC_("Countries","Brazil");
                    _map["IO"] = NC_("Countries","British Indian Ocean Territory");
                    _map["BN"] = NC_("Countries","Brunei Darussalam");
                    _map["BG"] = NC_("Countries","Bulgaria");
                    _map["BF"] = NC_("Countries","Burkina Faso");
                    _map["BI"] = NC_("Countries","Burundi");
                    _map["CV"] = NC_("Countries","Cabo Verde");
                    _map["KH"] = NC_("Countries","Cambodia");
                    _map["CM"] = NC_("Countries","Cameroon");
                    _map["CA"] = NC_("Countries","Canada");
                    _map["KY"] = NC_("Countries","Cayman Islands");
                    _map["CF"] = NC_("Countries","Central African Republic");
                    _map["TD"] = NC_("Countries","Chad");
                    _map["CL"] = NC_("Countries","Chile");
                    _map["CN"] = NC_("Countries","China");
                    _map["CX"] = NC_("Countries","Christmas Island");
                    _map["CC"] = NC_("Countries","Cocos (Keeling) Islands");
                    _map["CO"] = NC_("Countries","Colombia");
                    _map["KM"] = NC_("Countries","Comoros");
                    _map["CG"] = NC_("Countries","Congo");
                    _map["CD"] = NC_("Countries","Congo, Democratic Republic of the");
                    _map["CK"] = NC_("Countries","Cook Islands");
                    _map["CR"] = NC_("Countries","Costa Rica");
                    _map["CI"] = NC_("Countries","Cote d'Ivoire");
                    _map["HR"] = NC_("Countries","Croatia");
                    _map["CU"] = NC_("Countries","Cuba");
                    _map["CW"] = NC_("Countries","Curacao");
                    _map["CY"] = NC_("Countries","Cyprus");
                    _map["CZ"] = NC_("Countries","Czechia");
                    _map["DK"] = NC_("Countries","Denmark");
                    _map["DJ"] = NC_("Countries","Djibouti");
                    _map["DM"] = NC_("Countries","Dominica");
                    _map["DO"] = NC_("Countries","Dominican Republic");
                    _map["EC"] = NC_("Countries","Ecuador");
                    _map["EG"] = NC_("Countries","Egypt");
                    _map["SV"] = NC_("Countries","El Salvador");
                    _map["GQ"] = NC_("Countries","Equatorial Guinea");
                    _map["ER"] = NC_("Countries","Eritrea");
                    _map["EE"] = NC_("Countries","Estonia");
                    _map["SZ"] = NC_("Countries","Eswatini");
                    _map["ET"] = NC_("Countries","Ethiopia");
                    _map["FK"] = NC_("Countries","Falkland Islands (Malvinas)");
                    _map["FO"] = NC_("Countries","Faroe Islands");
                    _map["FJ"] = NC_("Countries","Fiji");
                    _map["FI"] = NC_("Countries","Finland");
                    _map["FR"] = NC_("Countries","France");
                    _map["GF"] = NC_("Countries","French Guiana");
                    _map["PF"] = NC_("Countries","French Polynesia");
                    _map["TF"] = NC_("Countries","French Southern Territories");
                    _map["GA"] = NC_("Countries","Gabon");
                    _map["GM"] = NC_("Countries","Gambia");
                    _map["GE"] = NC_("Countries","Georgia");
                    _map["DE"] = NC_("Countries","Germany");
                    _map["GH"] = NC_("Countries","Ghana");
                    _map["GI"] = NC_("Countries","Gibraltar");
                    _map["GR"] = NC_("Countries","Greece");
                    _map["GL"] = NC_("Countries","Greenland");
                    _map["GD"] = NC_("Countries","Grenada");
                    _map["GP"] = NC_("Countries","Guadeloupe");
                    _map["GU"] = NC_("Countries","Guam");
                    _map["GT"] = NC_("Countries","Guatemala");
                    _map["GG"] = NC_("Countries","Guernsey");
                    _map["GN"] = NC_("Countries","Guinea");
                    _map["GW"] = NC_("Countries","Guinea-Bissau");
                    _map["GY"] = NC_("Countries","Guyana");
                    _map["HT"] = NC_("Countries","Haiti");
                    _map["HM"] = NC_("Countries","Heard Island and McDonald Islands");
                    _map["VA"] = NC_("Countries","Holy See");
                    _map["HN"] = NC_("Countries","Honduras");
                    _map["HK"] = NC_("Countries","Hong Kong");
                    _map["HU"] = NC_("Countries","Hungary");
                    _map["IS"] = NC_("Countries","Iceland");
                    _map["IN"] = NC_("Countries","India");
                    _map["ID"] = NC_("Countries","Indonesia");
                    _map["IR"] = NC_("Countries","Iran");
                    _map["IQ"] = NC_("Countries","Iraq");
                    _map["IE"] = NC_("Countries","Ireland");
                    _map["IM"] = NC_("Countries","Isle of Man");
                    _map["IL"] = NC_("Countries","Israel");
                    _map["IT"] = NC_("Countries","Italy");
                    _map["JM"] = NC_("Countries","Jamaica");
                    _map["JP"] = NC_("Countries","Japan");
                    _map["JE"] = NC_("Countries","Jersey");
                    _map["JO"] = NC_("Countries","Jordan");
                    _map["KZ"] = NC_("Countries","Kazakhstan");
                    _map["KE"] = NC_("Countries","Kenya");
                    _map["KI"] = NC_("Countries","Kiribati");
                    _map["KP"] = NC_("Countries","Korea (Democratic People's Republic of)");
                    _map["KR"] = NC_("Countries","Korea, Republic of");
                    _map["KW"] = NC_("Countries","Kuwait");
                    _map["KG"] = NC_("Countries","Kyrgyzstan");
                    _map["LA"] = NC_("Countries","Lao People's Democratic Republic");
                    _map["LV"] = NC_("Countries","Latvia");
                    _map["LB"] = NC_("Countries","Lebanon");
                    _map["LS"] = NC_("Countries","Lesotho");
                    _map["LR"] = NC_("Countries","Liberia");
                    _map["LY"] = NC_("Countries","Libya");
                    _map["LI"] = NC_("Countries","Liechtenstein");
                    _map["LT"] = NC_("Countries","Lithuania");
                    _map["LU"] = NC_("Countries","Luxembourg");
                    _map["MO"] = NC_("Countries","Macao");
                    _map["MG"] = NC_("Countries","Madagascar");
                    _map["MW"] = NC_("Countries","Malawi");
                    _map["MY"] = NC_("Countries","Malaysia");
                    _map["MV"] = NC_("Countries","Maldives");
                    _map["ML"] = NC_("Countries","Mali");
                    _map["MT"] = NC_("Countries","Malta");
                    _map["MH"] = NC_("Countries","Marshall Islands");
                    _map["MQ"] = NC_("Countries","Martinique");
                    _map["MR"] = NC_("Countries","Mauritania");
                    _map["MU"] = NC_("Countries","Mauritius");
                    _map["YT"] = NC_("Countries","Mayotte");
                    _map["MX"] = NC_("Countries","Mexico");
                    _map["FM"] = NC_("Countries","Micronesia");
                    _map["MD"] = NC_("Countries","Moldova");
                    _map["MC"] = NC_("Countries","Monaco");
                    _map["MN"] = NC_("Countries","Mongolia");
                    _map["ME"] = NC_("Countries","Montenegro");
                    _map["MS"] = NC_("Countries","Montserrat");
                    _map["MA"] = NC_("Countries","Morocco");
                    _map["MZ"] = NC_("Countries","Mozambique");
                    _map["MM"] = NC_("Countries","Myanmar");
                    _map["NA"] = NC_("Countries","Namibia");
                    _map["NR"] = NC_("Countries","Nauru");
                    _map["NP"] = NC_("Countries","Nepal");
                    _map["NL"] = NC_("Countries","Netherlands");
                    _map["NC"] = NC_("Countries","New Caledonia");
                    _map["NZ"] = NC_("Countries","New Zealand");
                    _map["NI"] = NC_("Countries","Nicaragua");
                    _map["NE"] = NC_("Countries","Niger");
                    _map["NG"] = NC_("Countries","Nigeria");
                    _map["NU"] = NC_("Countries","Niue");
                    _map["NF"] = NC_("Countries","Norfolk Island");
                    _map["MK"] = NC_("Countries","North Macedonia");
                    _map["MP"] = NC_("Countries","Northern Mariana Islands");
                    _map["NO"] = NC_("Countries","Norway");
                    _map["OM"] = NC_("Countries","Oman");
                    _map["PK"] = NC_("Countries","Pakistan");
                    _map["PW"] = NC_("Countries","Palau");
                    _map["PS"] = NC_("Countries","Palestine");
                    _map["PA"] = NC_("Countries","Panama");
                    _map["PG"] = NC_("Countries","Papua New Guinea");
                    _map["PY"] = NC_("Countries","Paraguay");
                    _map["PE"] = NC_("Countries","Peru");
                    _map["PH"] = NC_("Countries","Philippines");
                    _map["PN"] = NC_("Countries","Pitcairn");
                    _map["PL"] = NC_("Countries","Poland");
                    _map["PT"] = NC_("Countries","Portugal");
                    _map["PR"] = NC_("Countries","Puerto Rico");
                    _map["QA"] = NC_("Countries","Qatar");
                    _map["RE"] = NC_("Countries","Reunion");
                    _map["RO"] = NC_("Countries","Romania");
                    _map["RU"] = NC_("Countries","Russian Federation");
                    _map["RW"] = NC_("Countries","Rwanda");
                    _map["BL"] = NC_("Countries","Saint Barthelemy");
                    _map["SH"] = NC_("Countries","Saint Helena, Ascension and Tristan da Cunha");
                    _map["KN"] = NC_("Countries","Saint Kitts and Nevis");
                    _map["LC"] = NC_("Countries","Saint Lucia");
                    _map["MF"] = NC_("Countries","Saint Martin");
                    _map["PM"] = NC_("Countries","Saint Pierre and Miquelon");
                    _map["VC"] = NC_("Countries","Saint Vincent and the Grenadines");
                    _map["WS"] = NC_("Countries","Samoa");
                    _map["SM"] = NC_("Countries","San Marino");
                    _map["ST"] = NC_("Countries","Sao Tome and Principe");
                    _map["SA"] = NC_("Countries","Saudi Arabia");
                    _map["SN"] = NC_("Countries","Senegal");
                    _map["RS"] = NC_("Countries","Serbia");
                    _map["SC"] = NC_("Countries","Seychelles");
                    _map["SL"] = NC_("Countries","Sierra Leone");
                    _map["SG"] = NC_("Countries","Singapore");
                    _map["SX"] = NC_("Countries","Sint Maarten");
                    _map["SK"] = NC_("Countries","Slovakia");
                    _map["SI"] = NC_("Countries","Slovenia");
                    _map["SB"] = NC_("Countries","Solomon Islands");
                    _map["SO"] = NC_("Countries","Somalia");
                    _map["ZA"] = NC_("Countries","South Africa");
                    _map["GS"] = NC_("Countries","South Georgia and the South Sandwich Islands");
                    _map["SS"] = NC_("Countries","South Sudan");
                    _map["ES"] = NC_("Countries","Spain");
                    _map["LK"] = NC_("Countries","Sri Lanka");
                    _map["SD"] = NC_("Countries","Sudan");
                    _map["SR"] = NC_("Countries","Suriname");
                    _map["SJ"] = NC_("Countries","Svalbard and Jan Mayen");
                    _map["SE"] = NC_("Countries","Sweden");
                    _map["CH"] = NC_("Countries","Switzerland");
                    _map["SY"] = NC_("Countries","Syrian Arab Republic");
                    _map["TW"] = NC_("Countries","Taiwan");
                    _map["TJ"] = NC_("Countries","Tajikistan");
                    _map["TZ"] = NC_("Countries","Tanzania");
                    _map["TH"] = NC_("Countries","Thailand");
                    _map["TL"] = NC_("Countries","Timor-Leste");
                    _map["TG"] = NC_("Countries","Togo");
                    _map["TK"] = NC_("Countries","Tokelau");
                    _map["TO"] = NC_("Countries","Tonga");
                    _map["TT"] = NC_("Countries","Trinidad and Tobago");
                    _map["TN"] = NC_("Countries","Tunisia");
                    _map["TR"] = NC_("Countries","Turkey");
                    _map["TM"] = NC_("Countries","Turkmenistan");
                    _map["TC"] = NC_("Countries","Turks and Caicos Islands");
                    _map["TV"] = NC_("Countries","Tuvalu");
                    _map["UG"] = NC_("Countries","Uganda");
                    _map["UA"] = NC_("Countries","Ukraine");
                    _map["AE"] = NC_("Countries","United Arab Emirates");
                    _map["GB"] = NC_("Countries","United Kingdom of Great Britain and Northern Ireland");
                    _map["US"] = NC_("Countries","United States of America");
                    _map["UM"] = NC_("Countries","United States Minor Outlying Islands");
                    _map["UY"] = NC_("Countries","Uruguay");
                    _map["UZ"] = NC_("Countries","Uzbekistan");
                    _map["VU"] = NC_("Countries","Vanuatu");
                    _map["VE"] = NC_("Countries","Venezuela");
                    _map["VN"] = NC_("Countries","Vietnam");
                    _map["VG"] = NC_("Countries","Virgin Islands (UK)");
                    _map["VI"] = NC_("Countries","Virgin Islands (US)");
                    _map["WF"] = NC_("Countries","Wallis and Futuna");
                    _map["EH"] = NC_("Countries","Western Sahara");
                    _map["YE"] = NC_("Countries","Yemen");
                    _map["ZM"] = NC_("Countries","Zambia");
                    _map["ZW"] = NC_("Countries","Zimbabwe");
                    _map["XK"] = NC_("Countries","Kosovo");
                }
                return _map;
            }
        }

        public static string get_by_code(string code, string fallback = "") {
            var my_code = code.strip ();
            if (my_code == "") return fallback;
            if (map.has_key (my_code)) return dpgettext2(null, "Countries", map.get(my_code));
            return my_code;
        } 
   }
}
