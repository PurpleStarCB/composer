ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.15.3
docker tag hyperledger/composer-playground:0.15.3 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� pvZ �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T�bB<�	�G��������@�G���}=ެ�/�Ȳ5��k�����j
�7 LX��;�e8P3��ހm�9̥�Z6pZ��A����"�������rl�$ !���mp���c �gZ-���:tu�CDg����K���e>u[~�P�5KSB*�H����wD��q�Z��0�>��y���G@�wI��W��S��A�R͞��Ya�9/�������!�K"G�?.
�r�_<�!RӌH�M�6]KA�]}
�~��E�Z��")�wޗ���T����X�㏠�S��{݄*��`Y��_L����;?��s�R�K���a��+�:@Ȓնf��50�$pg��K�\�K���a��w����|��6�{�A��k�x���Lĥ�/. X���&`�v����D�sᄗ�"[������ ��,P�i6pL@Z�;�M!����ˇ9P7-�9!�촑�`��v@ǵȞ�Ϸci]�a��"�d!��9��ǩt?�u0"ACsh9��Z:Ii:N�ތDpNӭ����G嘦n�Iy\��2���4-Z�@R~	O>]S�aS�2֚&
	a��j�~ϴT��D
0HY�M��4�fRlSwI��D�w�������5W������E6���w@(D>Ꚏ@�����xT)��i�A��EC��P�S4��iHj�q�yY|X�k7�����$&rep	�C�3�˕�3��d]O�Ӂy]����s'�?._�������<��u�P�$�&t@K�u X�mvND�rC3�C�����s�0���S�!бA��3F��7Ě<���`Y��!i�9)M����1۫|X ~^����urT�q�rR�L]�̅q�0�]��{�Tr��6l�6�A�N�^�V���=%��Aa��Ph�����o�ق{�nX#�d�zL*��|���
��0p�UfڪN��`}|��Ty�#�4�>m�@�����q�`��v��:��O.��]͡��쪉���&n(�9(G��A�Hq@��)M`R��,�}�����	~���:9��Y}������m>�7�`���;Q#,W)���$�gT�^ P�Ny�ŋ��!��4/���a<t�9~:��¨���K��
S�2��m����cR,�\���������/����E!6��<���YxvRz��Ygަݣ�b�k�2u�!��k���Z!�'l��V�I�J[1�0��\�}9U�T�~�S�q쯾aW���Ջ ����ʡsl�f�d)�z�)�s���g�#�ٷy��fװ���mt�mM���Y�F��x�-��F�����)O`mu<K���+r���g����C�&;/��6��ϮTa��/yu f������%�=_]#	X���7`u*�?�U�w���#��嵢n���!0�vY,x����Z��'eI�̨�d��!�͊~�lğ��m�;9,0
;>�دh���o��X&�S�g5�e�	�+�?$\l9�/ ����^5���~%�	�'��*���穠n�m��¼� �q�M?�_��>0L����ܧ8K��<7i�ţ�R����̓�5���6��!�B!<;Ե30X�1ᡀ�Ҿ�:�)�?a0������q.&.�����8s��Y�����������e��B��?ϥ�Y�?\<:a�G������8��7�4�n�@�eZ�ci������P�0C\���9䬋ƣ�o�������ե�~�����D��'�d�Mס���ճK��Er���6 AFXz��7"�٨Ы�T:�	B��r9�;p���
��H��i�u$� ��!��	��p-DO��)D�&_=�	d��U5�ۑ��ht�b��+c��q�ę3��sg�w���A�a��0{@���4�~p���K!����8��J�r�_�?��2�Jf����"���7�B>:嬂x�Z�����8P�w�6���\X����;a+��ޥ�ia������TkcEn�����<�Bf�?��I�O���������?�I��[��)Hiy�^��g�&r<�7 ɹ��^�c��5���2��a�[�Dj�
���e�`�Sy�*��K�����5���pn�_q| | �.pȵV6-��������rlw3�gk��?�`�{����w�dS��Hȁ��k�9V�^��3Z��1C"���Trnք]4N��t�٘$���5he�5& ��>��Y�V��^>`�~�d���%�8�1SBo�0~���ށw��>�?��υ�pz^�? �VGٌD�E�4mg3�I.)�;��I���݀�2"�>�J�a�j�at�[���i��bL?�~mg�.^���=��uA]�S7��C��P��e��T�Ջ��|�r�s0hP��.�1@$�m��K��}������62]�D9��dp?3�A)w(W2�w3�[W<+�x�;�I��ֈ���4���C�l�k����4�\�ĂEp�mR�ϋ�8���߈r���+bmCI�B�M�rJT��o�a���!L@Q�����ʔ*���ѕ�B$3�Am0��bt<���K�/TA@ �w�lG˪H�N���D��Q�	�:�5��R�h#͇��P�(�I���HyC���S#�3!W��2!�֦��J�	����O=~ ɴK=Y)%���>k����>a�l?����<A���?I���)�������b6�m��M��@�?�b�1{�W��)Dq>�)�n���ͼ���1.,�-�����
��i*��~�bv�ةi �-�|��`_�� `H3���A�Pe�Δ	� `��"�x:����j�p��@`��]�]�}j�k�%����K,����!c}��+�#�������t� ;0_S|�on��f���q��o���||���s��&1oz
;g�x����/��<����2�{!��߷�{��w�~�����?����������_P��)�($6�
��b�kuQ�H$b�ZB�8D"�Ę��%��ń�H���$�6$i�?�e��-3IxE^����NG';��YaV�c��,o+��_e��iئ�hn{�+�ȬV�Q������_�'���|�͈�2��[:��?���w�[a�����}�8sda�ղW�i�1F��aB��H�i �O����N�O���]���{'w����r�_|d�wJo�c��/\�QZ>�}1p��X�G�u�jh*Nz�e��qQ�a��u�?h�{��s���ur{����p&S����}hF#G��Q�=��,�!�6p���$3۹ ��l.%W24�����Rۧ����r/����\p�����In���q�̴�b/�8��'��S.�q{�yfS�[�2_�$����a�,s.����!&UI�
�ڶޮE_��(s�=��^�RI�<-���P�Y�X�Ϗ�������0+��D��<㞼n6k���IY:�	��NZ�N��
ͷ�^{*fo����W8�	�J�ۯ�#�vJӸA�[��4Y��^�x�>,�3�W���L%���.������N�J[�W2G�dѫ�Y��֨
Y7�9�I��u�v���Ő{���QɁG����ȗ%mge�L�k��J��d2����.�ń��l�R��^fG�rrr���=K���Y��?4����k�x��Trbi�G�ʫ䎱�::��j��ʻY��5M��O�'�^z�P���zP�����v��{Z�$���K��{�d�W$}��H�y��;�|R�od�SYΧlR+5�+��]9�l['Ѝ's��[�*��z���6ր�߷�T6�ׄW��n^6�5�=������TS�bJ�w���F*��P�#q�'��D�i�<��s*G��a��R#�\�,���v�U_5�f�3�^>w�o�ׇ���i����w�B�$o�5���SԀ���G_�L�����c�?]�'>�Z/����8<��=�<c0��-�tn����G�����!�h�O]�%,��g�����(�/��;�� ��c�����w�,ߴF'��$6T���\oo/�kj��֪�3'��!W�_�����w�l)�ݢ!�Mlr�d�duSv�Z(u���y�����vJ7��P�1#���bI�KYI��a[k��GF�4�ʾ��ȑt���w*j�d�i�S����w�b���?����{��ϋ���$����~3�����%1�:I̼>3�����!1�:H̼�3�{���1�:G�4߈��5��c�����'^�������d��[��U_£��������,��_5��Kݿl�����v]J.m��\T�ņ���ɦ���}�?;j��G�xЎ>f���I6�� �-��v��D�4e�������i�A�߳������J����VЁ���S��o>B��b�}x��D�������Rt������2;}����y��ꄁ��D�lPBt\�a�	��?H��y��	ygyuY�`����C����E��[�!�Fu��hĬY'Q��kY�� W%��U`�*}��}������~�z>����� �fj�&������M(��Rh/��W�H+���A%S��x��ICE��|Ǵ����ع��<��G1�l~�!<���o������F�dx�C��_5�%r��i�G�$�XӽG�3�9XE�C�D����o��O�[�]���0 y��MU�#0�A�>L�<m��p�A�{��Q���j� A@˂}$b�KC6���k�(�Ox���>Fuz&�K�����dB� xZB\��@�I�����"(�������tz8@'���4���t�NPFe!�W��G�[��6�������8����_�O������6Nxs��n��"<���e��F��%{#��45r���mۅ��+H�K�!u�&I��V!��:���!���~���v`�����i�4��u��,N��·W�`�c\!N�� 6Ft�=d"σQA�����%Ƒ$���ahr�����a��|k���v�SlK��L��r��.�͡�?���v��i�miPs@H�0�"-h.�nH�+,�!�8p@�p��ȏ�.קk�jF���TWEF���_D�x��܈K2(��K�4='us�%����/@��ܵ_�MB@�A�+A�&��>��3�r�\� �I!<>K%�e�Oc�yu�Uz�p�x��l�<"��Z3 ��k����\��"I� U��;�k7�E���"�A����fH�3�s]Y�3�)�D*k����Z��Cވ�y�N*5�938!��(��TxE04�Z\����g�^$+غ��SM����!�,k�r G@E	̡�u��b���܋��<.�-۾�Q7���8f�Ip�:r�����W.���>��9�m[���s n`(��qIQ�7;~�����!�[����]�����]	m?FAL/l���?�J����4Iܽ����=|O?K���s������w����?�B3�w����ǧ������!�}B`? �%��^|�����	z+�*���\L�G�K��٤�I��J��tF#Rx2���$���T��T�J)9�Ҩ�J�$՗�9RM�_(R�=����_���F�:���f?���g��)���;���}����7�Wׯ(��߼����X����؏�������>�5�U�����g�c�|�Y߾9��� ������Qp�`�rm�Ͷ���+i�}�v�>`t�t0<���>aV�����qpu�E�{�x�Bc��1����//�Kr3lwAZ+�����I᤻N�pғ@���k�y�P�]�.׻"m�BSp9oh<�N�ng1�rKyd�f�-��[�s	!�7��<�N�:�C��܂�W��a��!\�؞uɜ#4]���2,�-�'������a�$�]�����:(/��Z9$*	��Q�+�v'��r���NL���P+7:���P��B�:o��\+6�iP�HվP�]v����F)��`���H���J��G��E�)�?h�uQa�+�vix���'�N���x��%�<�؜^"n&ҧ���)w`���d-+��?�����/�& ٤y=���$����t%Nl�˚�jϨ���=}��۪�vW����G�Ҧ�Ҽ�j;M�8���kg8=�'��a���=�[�������tgTrgT��3*a����*�d���J���RBi�P��b���D3ǜ��t����f~�<+v�/D�1p!t��b�A��yD3�R�ڢ���z�'�@�=ܢ�˥�,�?G�������f1S�%Y��դcdz���,�y��r�9Te��I�L�nt�t�ЖR��k���є ��kI}���\�`��y��Yt/O�R����\u�:����*�$�d�JF��nr�8u�?�4O�j6�
��F�R�N�5�i�na���9cI%�r���y�>�d�9kVKCR㊵�C#��kS���x����~??�g�#�*�&���~�ދ��b�b��_��W��]_�+���W���Z������7|_xy�ɇ�B-�P���c���Z�^��o%�r	��&�C:���_���}y9�R셰�U���[��(+���b��M,r���7���>���؏��~�~�f�ť����L��2�w��hL��,�\�y�V���/��[�X���<�M��[�˹$yĹ��h���®�5G9汮���>�r�m|$0�� �j(TQ:"-2���Y�a\h��HN��`VD�������;�k���K�S��������ni����q0P�t~$k�=)�΢���l��:ʺ�Oʇ�u�#��y\&�d<�R7�H&XN�ѻ��f�zT`D2�RB�#\PY�a0yF����`�n��~q/���8R�:h�d���5��|w���A�WK4�p�AG�rX?*ʄ8h�F�.jG���4��D�ۮ�%D�9���'f�R��כ�+���J(�`��%�/��֥D����*ʍn9���QC�U*\�R��٠�:#�'�]����e[A.���@AfG�A �����+rI��.�'ܲ��U�y��ǆy��	W	��.��!������_a(w�Y�x5�E���rru�:��)ԝ�.��J��mqV=챍�U+��a�h�'ZgU�)�iV4��6G�6W��N��F�d��U�t�{Z�
��C�k�@����y�r^�i��#�&�py��;��@Yz����Bi1���l/���=���ɴO�C=_,gDu l6�-H��([׊�C�\�Ŷ:�ʭ̼�1�>Ӟ��ͦFg�T�X*�����s�����õrbX�	���ʖW�'Ϥ�ե4Q� Y��P���񑑙	D���))��J\��]Ab�E�$�B�?��u�`����	v�#�@�`k=�Ba"��X L�P�
��^.PZ�q��>T�=;m��V��Έ�M�">�py��w���h�:ɭ��	!�t�խ&(Ʃմ�n[��b�\egsˮS(Q�+P�@��(�v�+�&����x�JѴ�nC/���w����bC)%��-�
�T�V�!�T�jȋA���'�GG�E�����IRa����1�	�q[�.>�F�+0��X�=.��̥��)�\�ƚ5�"b
���Z/� �m�>��_��U��Jd�7^�Nr�2_�R��
v��E���L�V,v/(��W������؞��r��^����l[�y��#9ʠe����W�a�?}��x���xX���k���9ʋ}=�2�������aJ��z>�>��+z��+Q8O�a��${`�u��- h0��=��p���_D�`%G�+���l�������8���/��SͶ5;F�`o��Oѫt���ܽ�2+�������I׸���D��j��(]r����g��������m��������P���z���Q�5�}�ްt����C�������0��Y�o�"P��HSi�9�]����]נ	�e�f�������6!J�ylѻfn����:��~w?������*��+6���<~�>�	�F�Y7���l=��V}C��'b�wtbG�a���S�z���)�ny&A���q\�Z�zE�!d��Q�aɌ�����g1m�4��SUR 5@��)�]#{`*z��5́] �3��pl�84���<B6^����$睸=�f�k@f�AA�.���_�y�%Ϝ� �/@�kk5d[e��K85���A��}��v�0� ���EC-��C��_=��XGF�sʹ&�Xύ�5���u6��a�"�x�.�A��1��Xϳ!P(
������&/��Dr����
v����<P���P:V��H4��X9�Z'�!	̀ʸ�}O�k& u���+�D2��M@8���zQu�K����\{!�5v��_!�ѕ�º���Bce`M᳃-�N���*@�m*r��`Q�_CBH��m#_�:�Ř����������m*���Kk�}��5�@e��7x�#�� 3"XB�C[8�<�}4
��a���[В���9���E�V]?�T��v��!
(��&H>�ǁ~<�%��5E�6'qZ�I�T3�e�Z�i�iJ!#E�/(��8<\��8�BKtR���@VƁ�\2L�1��?���M�á�J�٩߄�,�n�ה�(~��;�.:ň��^���DLd�~����1�R\�u��Y�~��7�Ã�g���e�[��#�e AC��P -�8��!Q�E\��FmfG���F� `'�t��g#�G�MZ��#d<�-�y���e��do�����ʰ�pb���u�B^�M��R�]\w����M����sٸ�D{WG�|زսI���/N�@�°�Z�@��-"Kt���h"�6�lt۫���p��	�2~������H���B� :��݁��2q���I 'B�~(;�Z�}���qc���M����4Af��?b?���5��>��U���|��ur�i����1�L����+�h�m����ƚ�Zӡ�765�����@D�ݎ(�"��v�At�o׎�;:�+.�m��<����g��q��*Cn��������m$?d�~�}�}�(`(�V�#��+Q0��+D��#��;��4��q�>����$4GI���䎊-�y�5�oU���Y읋j�˳_�B��]�y�Z/l��>[;I�R?I�eR�d*�#5�JjI��N�E�j�OH)'��9R��r?��R��&�i	F�E�^�q�Ca�����Xn@+�@��o���x�@r��]��(v,H8a̡�|6�DN�Ӕ$�2���UR	RK)���$)�N��Mg��$�0���3��i��FHiI${����ω�z��@oi��z���)����K���<�����bPp׾`g�/�X���ȶ�d�&��"W�t�R+V�C��D��~~1�%rU�e�\��G�~ni�o�o	�X��O�Q�%Ew�Wpr΃���+B�γO"�c�����t�|�'��@Pރٱ
Og��I�<WK�S%��`&#\:�V�D8��A�p���w ���g�4���b�xl�	L��C8g[ݞ!������~�a��(+]��&���W��u�kn!:��/�|5_c�%=�`9�]�,z(sU�^����X�'	��:1����l��V��(~����c���E��v�l���������Z���|�Z���UN�Ԛݓ�����v7� �@�l!��A��b�,���Ĳ^�-��-�G?YZ���=�[3e�2�������c��
&H��Uy��eSϕ@C�-��9���Co&��%���!abs�`�It�<��h�>?�_A���nd�M�[�|�v���l}B�Um��U�x}1��-��dFv��~���M b��l�8Ŀ5�`G,s�nV@ہSa��H�GEǰ�϶u�|�߮n�-�W��ɻ�_��>�����m<��'q���[��O�}������L����6җ��7E���������t��"]'l�]��t���&�����/�'	|��S�����t[��<�J�����l�-�Q�/j����;�﷒�<��y���@�\=�|�$�L�K��Q;�����nK��Ԝv�}���LV% �H�*��������d	EKg�l?�$�LRΤ�����"%�ؾ)��j�/��?�&��ɻ�_��"��v��g���?{�֜(�u��߽U��t�V��TDP<p� "������W���L�L��Н��R�Lz�����{=��4���6M���#���أ]��q5B�r8���y|R��۟�6��{f1R�l�.���Do2$�y�"��2�&������9镳s����՛��xtX&]iLb|x�z�VZ��D�统����ф��������<R��<F��=�?���_������'���@U����u��O���������o���<j��ۤv�o���?���������J� �ZŽ�KT=����k������
4���r�S�ա*����O�`�������:�N�����!4B���?a��4@�����ϭ�������Eh��~hhB�O����8��V����V���?�?�?Xr��ʓ��l����gY��g������}[�D~d���=D�������~"���,���ͬ2��߷������Mgf�̭�YK-��E����%�G3ť����v�����Ty�dI��AϜ�����,�v�8Y��8����\�^z��}��}"߳����d�fJ�%r�h{o�A�],S�9��4��g��b��S���)]+4qV�8�Hϑ3�%tي�shE;J��<+��1���4	��N��GBg�	���؃s�>h�.��\��8����4h����mh��{Z�@����_#�����Y�)QU�����'������O���O������
4@�eq��u��ϭ���ϟ���?�_�����D������������Z��g�>�\X0���I<d��������g�����/e}�N�]��y��?v��Rf>qV�$�,FR�G{?7���j!�G�9�=Fuw|�a�VA�UQ�
\*y���fAf���a��َ�Е쩬G�^ׇ�.Ou�� �Ph�%�J��BM����>�[�����Lu)hTLtK�H��O�ޚ!������r��؃h���vT��YB,�3���R�8�OLr�qK-�M6Wy���|:��cf���oh����?�_h��[��,O!��5 ��ϭ�����7����/��W�&��|��l���y�1���h��h��y?�B��|6�  �c؀ � #&�I����;�M��G��P�W������}W[�c1�m�`�,͸ӡ�ϻ����S�]���>�;җ������D��'_YǴ�+�s�vG\�u�ٲ�����<�t�ْ��X9�"%�e�?Ć�0��;4��N~܎Ϊ7�B��[ф��?�C���@׷V4�����>4��a��64�����?�e`�o�'D����3뿣a*�QSZ��$b#9��#�x�Y�J�]��*��0K�/���'��2��!��qɘ�3z�,�%�(�8���Ka�Ei�R�[�KR��űe[�M�Y0����ij�.��[ь� ��&4���?������
h��������/����/�@��������,{���_xM���U�E����aD�I���f���2���yv��?_Ւ�_
����v�!W����; ��o�� �_���; �R5茓`%<T����W� ��"�F�&��~��Z�n�5�vd�j���+�~{��,yԑʀhE�h�g����[,m�<_>H�w���<�x#�nV�H���$��n9O�W��`:m���k=p#�-^�'"��pa����.E���Ƣ�sx�z�Xn�H�8c: �AfP���R���`�K]lI����S�x��		��?p�@ �)��Xô�q�F���Wbk6Ӻb����")�����.[�B,�B�t`_$��|��]j���	WDg����em���Bh��A�N=��*������GsQ��������,�U�	�}��������?d�5U��w���,����������7�	����P���y�gh��}��0v��q"���=�c�Y�c������6�$�9Ǉ�ㅰ��ahB��`������������?�Ku�г�ҵ	��}b<��l��؏��1t*5�����5���.R��*���nՎ��]��*F�vC��]�)�F(Ks��\�&8T"�ʂ���|r�x�mۇFn�0��V4��ǩ����S	>��ou�J�?������!(���@#�����a��"T���|C�{��_7�ĝ���r�n_���AU�����$�_x5���������q���;�t�Ʃ�N̻�e�[���o�0�ȏ�~߾�����������wQL��(�&��S-�ȫ�ߝ#��E�ϖ�����5��L��蜑��dd�����d�,f�&hmon�1��.��
�3,V���pĸ�r�D���m��T��r���۳�F�ƹ��������<r�ׅ���6V��`p��6��D��R�w��ʎ]q$Ք�L3DR��o�B��J����r�XY�Ck;q�1��h�F�1���]�i;Uv��:�-d:ֻC�/ų��ጄF�eW�&迫ڃ�kB5��wo*������	�O�$�քj����&�����*���7���7��A�}��˓,�F��ϭ����������ӗ�4�����,��U �!��!�������o�_������~iݯ�U<����$����	�O`�}�O�W������?u���~�����B���5���v���������������?����������U����?P��P	 �� ����!4B��w�/�T��?��P�n������?��+B���Bj@��G�$�?T�����������I�A8D����s�F�?��kC���!�F#���$�?T�������z����+A�_G0�_�����������;���Q�����	�?�����������K�B#��@����@��:�dyz���P�n���'��,��աI���W1�c!��,`9�.���"��J7�������9��}��<ޣ(����>��/���$�C�_�R�G��Z����^��N�Zq
�V����nހiF�����1��k�A܁0�,|�I�����H3��q9IF�����1��κl{�*��FJҖF5^;sD_�v�θKt�HZN�N��^ ��s��宍��Pԗ�.}-��^T�ox�Є��?�C���@׷V4�����>4��a��64�����?�e`�o�'D����3�a@�������j;$o���]��s�/���_������v�έ��%JZ6q8,�y�es1]b�q�yj��s[ݣ��(��Q�\�v现�uy8 ���Gy�]�
m@��V4������ߊЀ�?����{�+�	�_��U`���`������W���4B�]������>���S�_�O�'��1)M����f�:qbd����kg?[�=k����EWt;��_?ց�[2��]�9�wv���Ӛ�3�՝����2���$V��<Y�	���	��2j��H[1+�,s~� 3ø����Q%5؞�靴@��$��N�2���t��7��X����p#�-^��#�.O�Q4��i,�>������&R91��d�h���@ �)�]��;{^֗��S�����{�i�l������G���]M�Eu4�����{��ϣu���@�Ѯ;�[�qO���vG�{�?����z���o��o�����b,��J���������8Ͽ4��é����]	>���)�F��*����?���h�~������@5����	��CU������u�����k��aK�0�|��Ѝ���m�1{�q^�ϗ��u�
_���mY�^�?$��fiZt�7���^z�	��{?�N�d�!�����C�z~f�D_z�E��u��b�b]�n��͹��� �-�؂-F��U����(��:��%MghҮ�1�5T�!�%������)R&,&wrMK��l�;�Kޚ(-�}�`�I������#\�<�8WLma�ܢ垬�'�͛��s��c-�h�ܾda�b�!O?l_�evQ]z�L��ȌEId���ޓ-��o���Q�-̨wB�&�Z��9��ڣ�����]A!�e?�8��m��#N������?������jEj$�ꉅu�aGo��Ȝs��\���b�n0ᭁ�����{A#�}7��ߊP��c}���|v����2���)&�u=���"`)�_x$�3`���^��6�?
M�������?��U��9�/3�B��Q�~�c�����?�{�c�;�̐Vsb����{��W���G���
�����3����1��*��������T���_�Q����c���h���5��_��?�����i`g�8'CaGSf���?Ϯ������:�����������[�9����w���7xS]t^������b�!o��L2έ�)�x������0l�L�g�����n6��Ϻ�x��X[� m�0�v�"?���q�I9ݴ{Q��z�퇼��{������+�&4�g�iI���^'�jt�ȳ��.'�:[���<���x^��i�����ٌq��,���%J��>jf��S�v���?HvXf�]��pI%a�=m�uգ�@�=\Tv���}�4A���`��Tp��PA�p��� n���~E�a��}��=��_{�ޤ������NN�ԙ��S��
��/SS9��xA����m��D���N����U%1�(�z޵���o1b_0+4��?C��E��{C��������X�����3���*��d�lH�V=��ء,N�U-����W��!r�#U����%q-؏���{-o}�'~���%����Y��ۻ�8��4H��ג�_X�1��������������\��2CZ����?�U�ϒ��·������i���D-(�`�i��u�To�n޽��������\�?Կ\�Q:q�˺��us~)��} �q�/�ɱ������\m���s�O�EÅX��\a?:tu����\p���k�i��V����^��:'�xZ���I�pok�v�MN䠿k������f��_����3G'iY�0�[7�i�]O��hێ��ܒ#,��i�cz�m���%�L��E������B���y�g��H�p�h}h��Ӧ[��������|[��a�����d�qU����Q�\C�Ռq�m�ӡ�VG��`�j�ݫ_��h�m��z�v���ٕ>U������"��e��({�9�Tq'�B�ޔ�ӯ\��O��G�Z����B���A�U ��o������Б���D�쑉��z�'[���T���0����O���V��c8td�����eA�a�)�?���������?������oP��A�w�o���W�B}���H�������!�O�L�?{U���D:�5�Z�� ���^�o�����T@��I� �s@�A���?I\�����R��C]����#����/�dD��."������?��H�� ������	��������T@�� )=�߷�˄���?����Ȃ�CF:2�_��p���P��?@��� ������P=�߷�˄���?22��P�����?��?������P��?���Q��R����#�������F����
������L��0�0�������%�g`�(���<��7!�G��������E�*���R"�o0$A��^bg�f�)�ef�U&Mʰ��U,ѦɖL ò��o�)/�l���c�V?�_�,�����a�:����]e�E��8���r��E��7d���{��_��ǑX�e<Ғ��N�f���dN�"^я}a��R���W#ٲV!���p��¼�%����k��$yT'�<�緃RP��ڡE�%�̙J����T����ƨӶ%1d���nq�z[��K�uTj�~y�W<�y���N
��Yh���':P���
F}�@���Б���?�@���|��@�W�~ɂ�C������� ��m��Ǳ��売a���i۫IK`w���ٓ�%����ek�l��k��7]|+��ĸ������#�WŒ����f�h�5k0S5^��P^ζu�j3r)�v�.�)� �{-�h���������=��xQ�Bdb��!� �� ����!����L�?���E�i���������ZM;�%/�7Z��Y�{����?i�����!Vx��ʄ�/�/| ?���{����
�76�Q��q�՛��ݼ�ی4}8k��8ϖx�0ʏ�h�߲nͰS~�cK���v׺䶱�f^Q�h�J)��6-�z��68��������R�6n���z��5�>o��1*�i
ф�;�j�W�G/�?'(Ql�|��憨V8�~��{i���O�=��9"Gp�S���.AtdCj�2�ѭ�?7�ue�E�?;LJ�(`�T:� ���؎�k�T�5�tyw`��eȸ֪4����=�K����?������d��������?�j�G�M��a��ۓ	�go����i���?=xY��������������A�� ��'I`�/�����\���?���
����"ਯ�=���\���?`�o*dI��
d�����W�1�
������P��~Ʉ�#n����K��V�D
�����2����22����#2�3���8���7�?NI��������}�8|��"�33˸��������y�����܏$������c�G�a؟��HR?�W�������ۺ��^�7����v�Nثv�!U�#0j��Mi���L��k��h�ָ�O�yg���Nmn0���M#��(<L).(Y��x-���x�0I��~4���������t�vx�`;�����0ϲ�&o��b������G�2Y��v;�s��q��:џ��!���1K-�-A��8�:�z9��ﵡ�Vt*Q��9�Vf~�w�#e�RCi�z������td����?2�������������2��0���,���C�H�L��7��0��
P��A�/���6��`�����"�/�]��}��L�?���#"C�����d"������V�_�$��_�T��M�:���ʥ�ڴ��������>�E�}�h�uwe���K��� `O���P�[��?�Tۭi�VR*�Q`؍�N�^��P�I�\/t��3����M���IН7��y�4�C��D���3e���� `I�����$�?��F\��{T[��e��:���+�b67e�U�ٖd~.����e�#(<��M�7P��I84�ה��(̣�4u���֘�4#}���a��	�G�X���r��ip�W�>�����_��Hܨ�X�O���?U�XC+���h�V.i欈�E�:C�MZ$���&M���eц���Y.��a>o����ɂ��Z������\���NٞC�%�>�z�	���O45b1�����R��dN�r����1܌�Bmo���D?��ީ����j��KZ��]Դ�~?S�S�!�Ӡ���AO�Q�0�Ƣe���6��cX��d������@��'�@�� wN���Б	���?�@��O� �a �Kq�dA�!�C�ό���n5�/$�-�|a�c��F�����Pj��I��#'�l/����v�ߒ��U�Z}�R���ڈƼ����/Y�J��c�=�u�SͰ%��D��^m︎V�5>�	��k�F�5��N�@��� o� FH&�A�2 �� ��������hȂ���"�?D|����g���>7<f���V���Q8���Ք�{������r ��B /s �K;�i+�	������U+
���j���r.��r���S[��bZb�#���~�.��|y`�h�^3�@իDi�on[�j!����6K|�qQ������sUjф�;�*%}���u5�/��[	&!����A�+�d7�jIT�p�[֦c���]��#L=����Ql�~��YN���p�ύ�D�~ڶx����y�y]\j��Z5��l�P>�sw���;���i��M�ح}��Qm���Q�sfO��bmH�s�V�ڝ�`Bu�⤌���w��|�}�f��um�7��b�����SdA���ܜۦ�������O��o�7�Gm+����aN���"|$�c��W{�U����C���������~9��U��	� �a��]ȯ6�2������>oГ�Ga������J�����^��8?�bs��J%w���L6o�7��r���㖇`�}���?�!����'I6����{���q��1�o9�������?s��o��<�qÜ�Z%w�Zsg��a��S1Cӈ7Ƿ��<��&�u��o�ڹ�:�����=˾��¹�3v�o���9~���*J��w���3f��x��߽�7���{�AW��������]���y�,~�;�����,��^?�չV��x߿�{n�>��q����?a7;/�a��h�ŗ������3��9�M?w�sr�&�x#�/s\C�w���W9�E�X����:��[�J�����9A�3s�ko��u��JCl����J�Orwk���3��&��߷^�;�L�������Zz�����|��1�F�3M��6�2�|����q�ŇM�F��_,N�����.��Q�?_�¥���������!�W��I<|v�ߘ��ۢ���赅VSR����� �\�]���y��/?)y��W]�Er��/O���C-                 �����t� � 