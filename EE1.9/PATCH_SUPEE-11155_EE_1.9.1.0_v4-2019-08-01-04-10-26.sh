#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-11155_EE_1910 | EE_1.9.1.0 | v1 | f05ee926a3539e0391e0799aeceeaf8af04ae9ba | Mon Jul 29 22:12:14 2019 +0000 | c85b54c001627671640bf2bb854067ed13156373..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 77b552139ae..4a0ee19f910 100644
--- app/Mage.php
+++ app/Mage.php
@@ -691,9 +691,9 @@ final class Mage
             ',',
             (string) self::getConfig()->getNode('dev/log/allowedFileExtensions', Mage_Core_Model_Store::DEFAULT_CODE)
         );
-        $logValidator = new Zend_Validate_File_Extension($_allowedFileExtensions);
         $logDir = self::getBaseDir('var') . DS . 'log';
-        if (!$logValidator->isValid($logDir . DS . $file)) {
+        $validatedFileExtension = pathinfo($file, PATHINFO_EXTENSION);
+        if (!$validatedFileExtension || !in_array($validatedFileExtension, $_allowedFileExtensions)) {
             return;
         }
 
diff --git app/code/core/Enterprise/Cms/Model/Page/Version.php app/code/core/Enterprise/Cms/Model/Page/Version.php
index e799c258ea9..c12087062c4 100644
--- app/code/core/Enterprise/Cms/Model/Page/Version.php
+++ app/code/core/Enterprise/Cms/Model/Page/Version.php
@@ -149,18 +149,21 @@ class Enterprise_Cms_Model_Page_Version extends Mage_Core_Model_Abstract
     {
         $resource = $this->_getResource();
         /* @var $resource Enterprise_Cms_Model_Mysql4_Page_Version */
+        $label = Mage::helper('core')->escapeHtml($this->getLabel());
         if ($this->isPublic()) {
             if ($resource->isVersionLastPublic($this)) {
-                Mage::throwException(
-                    Mage::helper('enterprise_cms')->__('Version "%s" could not be removed because it is the last public version for its page.', $this->getLabel())
-                );
+                Mage::throwException(Mage::helper('enterprise_cms')->__(
+                    'Version "%s" could not be removed because it is the last public version for its page.',
+                    $label
+                ));
             }
         }
 
         if ($resource->isVersionHasPublishedRevision($this)) {
-            Mage::throwException(
-                Mage::helper('enterprise_cms')->__('Version "%s" could not be removed because its revision has been published.', $this->getLabel())
-            );
+            Mage::throwException(Mage::helper('enterprise_cms')->__(
+                'Version "%s" could not be removed because its revision has been published.',
+                $label
+            ));
         }
 
         return parent::_beforeDelete();
diff --git app/code/core/Enterprise/GiftCardAccount/Model/Pool.php app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
index e21b03ea480..ad585d784c4 100644
--- app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
+++ app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
@@ -107,8 +107,9 @@ class Enterprise_GiftCardAccount_Model_Pool extends Enterprise_GiftCardAccount_M
         $charset = str_split((string) Mage::app()->getConfig()->getNode(sprintf(self::XML_CHARSET_NODE, $format)));
 
         $code = '';
+        $charsetSize = count($charset);
         for ($i=0; $i<$length; $i++) {
-            $char = $charset[array_rand($charset)];
+            $char = $charset[random_int(0, $charsetSize - 1)];
             if ($split > 0 && ($i%$split) == 0 && $i != 0) {
                 $char = "{$splitChar}{$char}";
             }
diff --git app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
index b7b2717b2bd..fba4dcb9af1 100644
--- app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
+++ app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
@@ -492,7 +492,7 @@ class Enterprise_GiftRegistry_IndexController extends Mage_Core_Controller_Front
                             $idField = $person->getIdFieldName();
                             if (!empty($registrant[$idField])) {
                                 $person->load($registrant[$idField]);
-                                if (!$person->getId()) {
+                                if (!$person->getId() || $person->getEntityId() != $model->getEntityId()) {
                                     Mage::throwException(Mage::helper('enterprise_giftregistry')->__('Incorrect recipient data.'));
                                 }
                             } else {
diff --git app/code/core/Enterprise/Logging/Model/Config.php app/code/core/Enterprise/Logging/Model/Config.php
index f64e13428ec..e40dec05c41 100644
--- app/code/core/Enterprise/Logging/Model/Config.php
+++ app/code/core/Enterprise/Logging/Model/Config.php
@@ -83,7 +83,13 @@ class Enterprise_Logging_Model_Config
                 }
             }
             else {
-                $this->_systemConfigValues = unserialize($this->_systemConfigValues);
+                try {
+                    $this->_systemConfigValues = Mage::helper('core/unserializeArray')
+                        ->unserialize($this->_systemConfigValues);
+                } catch (Exception $e) {
+                    $this->_systemConfigValues = array();
+                    Mage::logException($e);
+                }
             }
         }
         return $this->_systemConfigValues;
diff --git app/code/core/Enterprise/Pbridge/etc/system.xml app/code/core/Enterprise/Pbridge/etc/system.xml
index 97bb5e028d8..b3d326852f4 100644
--- app/code/core/Enterprise/Pbridge/etc/system.xml
+++ app/code/core/Enterprise/Pbridge/etc/system.xml
@@ -66,6 +66,7 @@
                             <label>Gateway Basic URL</label>
                             <frontend_type>text</frontend_type>
                             <sort_order>40</sort_order>
+                            <backend_model>adminhtml/system_config_backend_gatewayurl</backend_model>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
diff --git app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
index 255af517a05..c0a710453a1 100644
--- app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
+++ app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
@@ -173,6 +173,9 @@ class Enterprise_Reminder_Adminhtml_ReminderController extends Mage_Adminhtml_Co
                 if (!isset($data['website_ids'])) {
                     $data['website_ids'] = array(Mage::app()->getStore(true)->getWebsiteId());
                 }
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
 
                 $data = $this->_filterDates($data, array('active_from', 'active_to'));
                 $model->loadPost($data);
diff --git app/code/core/Enterprise/Staging/Model/Mysql4/Staging/Action.php app/code/core/Enterprise/Staging/Model/Mysql4/Staging/Action.php
index 2cbafabe91e..70e71a2b277 100644
--- app/code/core/Enterprise/Staging/Model/Mysql4/Staging/Action.php
+++ app/code/core/Enterprise/Staging/Model/Mysql4/Staging/Action.php
@@ -66,21 +66,31 @@ class Enterprise_Staging_Model_Mysql4_Staging_Action extends Mage_Core_Model_Mys
      * Needto delete all backup tables also
      *
      * @param   Mage_Core_Model_Abstract $object
-     * @return  Enterprise_Staging_Model_Mysql4_Staging_Backup
+     * @return  Mage_Core_Model_Mysql4_Abstract
      */
     protected function _afterDelete(Mage_Core_Model_Abstract $object)
+    {
+        return parent::_afterDelete($object);
+    }
+
+    /**
+     * Action delete staging backup
+     * Need to delete all backup tables without transaction
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @return Enterprise_Staging_Model_Mysql4_Staging_Action
+     */
+    public function deleteStagingBackup(Mage_Core_Model_Abstract $object)
     {
         if ($object->getIsDeleteTables() === true) {
             $stagingTablePrefix = $object->getStagingTablePrefix();
+            $tables = $this->getBackupTables($stagingTablePrefix);
             $connection = $this->_getWriteAdapter();
-            $sql = "SHOW TABLES LIKE '{$stagingTablePrefix}%'";
-            $result = $connection->fetchAll($sql);
 
             $connection->query("SET foreign_key_checks = 0;");
-            foreach ($result AS $row) {
-                $table = array_values($row);
-                if (!empty($table[0])) {
-                    $dropTableSql = "DROP TABLE {$table[0]}";
+            foreach ($tables AS $table) {
+                if (!empty($table)) {
+                    $dropTableSql = "DROP TABLE {$table}";
                     $connection->query($dropTableSql);
                 }
             }
diff --git app/code/core/Enterprise/Staging/Model/Staging/Action.php app/code/core/Enterprise/Staging/Model/Staging/Action.php
index 418817713dd..f59dc427b85 100644
--- app/code/core/Enterprise/Staging/Model/Staging/Action.php
+++ app/code/core/Enterprise/Staging/Model/Staging/Action.php
@@ -220,4 +220,16 @@ class Enterprise_Staging_Model_Staging_Action extends Mage_Core_Model_Abstract
         }
         return $this;
     }
+
+    /**
+     * Action delete
+     * Need to delete all backup tables also without transaction
+     *
+     * @return Enterprise_Staging_Model_Mysql4_Staging_Action
+     */
+    public function delete()
+    {
+        parent::delete();
+        return Mage::getResourceModel('enterprise_staging/staging_action')->deleteStagingBackup($this);
+    }
 }
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index c581dbfdc70..f4b13c8f144 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -64,7 +64,7 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (in_array($this->getBlockName(), $disallowedBlockNames)) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
         }
-        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9]+\/[-_a-zA-Z0-9\/]+$/'))) {
             $errors[] = Mage::helper('admin')->__('Block Name is incorrect.');
         }
 
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 46aa95e4173..f69daf223fd 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -433,7 +433,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->userExists()) {
-            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email aleady exists.');
+            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email already exists.');
         }
 
         if (count($errors) === 0) {
diff --git app/code/core/Mage/AdminNotification/etc/system.xml app/code/core/Mage/AdminNotification/etc/system.xml
index fc556bf0546..a8c3f720162 100644
--- app/code/core/Mage/AdminNotification/etc/system.xml
+++ app/code/core/Mage/AdminNotification/etc/system.xml
@@ -64,6 +64,15 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </last_update>
+                        <feed_url>
+                            <label>Feed Url</label>
+                            <frontend_type>text</frontend_type>
+                            <backend_model>adminhtml/system_config_backend_protected</backend_model>
+                            <sort_order>3</sort_order>
+                            <show_in_default>0</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </feed_url>
                     </fields>
                 </adminnotification>
             </groups>
diff --git app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
index 4397be88c7c..4516befed0f 100644
--- app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Api_Role_Grid_User extends Mage_Adminhtml_Block_Widge
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('api/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index 79590c663ed..2fa05be69f9 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -125,6 +125,23 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
             ->getConfigurableAttributesAsArray($this->_getProduct());
         if(!$attributes) {
             return '[]';
+        } else {
+            // Hide price if needed
+            foreach ($attributes as &$attribute) {
+                $attribute['label'] = $this->escapeHtml($attribute['label']);
+                $attribute['frontend_label'] = $this->escapeHtml($attribute['frontend_label']);
+                $attribute['store_label'] = $this->escapeHtml($attribute['store_label']);
+                if (isset($attribute['values']) && is_array($attribute['values'])) {
+                    foreach ($attribute['values'] as &$attributeValue) {
+                        if (!$this->getCanReadPrice()) {
+                            $attributeValue['pricing_value'] = '';
+                            $attributeValue['is_percent'] = 0;
+                        }
+                        $attributeValue['can_edit_price'] = $this->getCanEditPrice();
+                        $attributeValue['can_read_price'] = $this->getCanReadPrice();
+                    }
+                }
+            }
         }
         return Mage::helper('core')->jsonEncode($attributes);
     }
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index da8259dde43..be341c42715 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
@@ -56,6 +56,12 @@ class Mage_Adminhtml_Block_Newsletter_Queue_Preview extends Mage_Adminhtml_Block
         if(!$storeId) {
             $storeId = Mage::app()->getDefaultStoreView()->getId();
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         Varien_Profiler::start("newsletter_queue_proccessing");
         $vars = array();
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
index 627b0c56a84..cd4f1c3fef8 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
@@ -46,6 +46,12 @@ class Mage_Adminhtml_Block_Newsletter_Template_Preview extends Mage_Adminhtml_Bl
             $template->setTemplateText($this->getRequest()->getParam('text'));
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         $storeId = (int)$this->getRequest()->getParam('store_id');
         if(!$storeId) {
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
index 8b267e157cc..a454b34a325 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Permissions_Role_Grid_User extends Mage_Adminhtml_Blo
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('admin/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
index b7e93dfcde1..c357511deba 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
@@ -76,6 +76,7 @@ class Mage_Adminhtml_Block_Sales_Creditmemo_Grid extends Mage_Adminhtml_Block_Wi
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
index b0fad5b4a39..1ca522ca07d 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
@@ -77,6 +77,7 @@ class Mage_Adminhtml_Block_Sales_Invoice_Grid extends Mage_Adminhtml_Block_Widge
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
index ae3685bc13f..0bfb29c36d8 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
@@ -34,7 +34,10 @@ class Mage_Adminhtml_Block_Sales_Order_Create_Header extends Mage_Adminhtml_Bloc
     protected function _toHtml()
     {
         if ($this->_getSession()->getOrder()->getId()) {
-            return '<h3 class="icon-head head-sales-order">'.Mage::helper('sales')->__('Edit Order #%s', $this->_getSession()->getOrder()->getIncrementId()).'</h3>';
+            return '<h3 class="icon-head head-sales-order">' . Mage::helper('sales')->__(
+                'Edit Order #%s',
+                $this->escapeHtml($this->_getSession()->getOrder()->getIncrementId())
+            ) . '</h3>';
         }
 
         $customerId = $this->getCustomerId();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
index 8bfbda4bd94..71c4811dc4e 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
@@ -67,20 +67,17 @@ class Mage_Adminhtml_Block_Sales_Order_Creditmemo_Create extends Mage_Adminhtml_
     public function getHeaderText()
     {
         if ($this->getCreditmemo()->getInvoice()) {
-            $header = Mage::helper('sales')->__('New Credit Memo for Invoice #%s',
-                $this->getCreditmemo()->getInvoice()->getIncrementId()
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Invoice #%s',
+                $this->escapeHtml($this->getCreditmemo()->getInvoice()->getIncrementId())
             );
-        }
-        else {
-            $header = Mage::helper('sales')->__('New Credit Memo for Order #%s',
-                $this->getCreditmemo()->getOrder()->getRealOrderId()
+        } else {
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Order #%s',
+                $this->escapeHtml($this->getCreditmemo()->getOrder()->getRealOrderId())
             );
         }
-        /*$header = Mage::helper('sales')->__('New Credit Memo for Order #%s | Order Date: %s | Customer Name: %s',
-            $this->getCreditmemo()->getOrder()->getRealOrderId(),
-            $this->formatDate($this->getCreditmemo()->getOrder()->getCreatedAt(), 'medium', true),
-            $this->getCreditmemo()->getOrder()->getCustomerName()
-        );*/
+
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index 2421333db51..5b25e90ac95 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
@@ -65,10 +65,11 @@ class Mage_Adminhtml_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Widget_
     {
 
         $this->addColumn('real_order_id', array(
-            'header'=> Mage::helper('sales')->__('Order #'),
-            'width' => '80px',
-            'type'  => 'text',
-            'index' => 'increment_id',
+            'header' => Mage::helper('sales')->__('Order #'),
+            'width'  => '80px',
+            'type'   => 'text',
+            'index'  => 'increment_id',
+            'escape' => true,
         ));
 
         if (!Mage::app()->isSingleStoreMode()) {
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
index 84f31c04c53..ca3efe8ba08 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
@@ -64,8 +64,14 @@ class Mage_Adminhtml_Block_Sales_Order_Invoice_Create extends Mage_Adminhtml_Blo
     public function getHeaderText()
     {
         return ($this->getInvoice()->getOrder()->getForcedDoShipmentWithInvoice())
-            ? Mage::helper('sales')->__('New Invoice and Shipment for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId())
-            : Mage::helper('sales')->__('New Invoice for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId());
+            ? Mage::helper('sales')->__(
+                'New Invoice and Shipment for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            )
+            : Mage::helper('sales')->__(
+                'New Invoice for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            );
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
index 113e8c6a984..ff74e8a4b1e 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
@@ -59,7 +59,10 @@ class Mage_Adminhtml_Block_Sales_Order_Shipment_Create extends Mage_Adminhtml_Bl
 
     public function getHeaderText()
     {
-        $header = Mage::helper('sales')->__('New Shipment for Order #%s', $this->getShipment()->getOrder()->getRealOrderId());
+        $header = Mage::helper('sales')->__(
+            'New Shipment for Order #%s',
+            $this->escapeHtml($this->getShipment()->getOrder()->getRealOrderId())
+        );
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
index 0f7935f2575..2960a5ffddd 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -287,6 +287,16 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
     {
         return $this->getUrl('*/*/reviewPayment', array('action' => $action));
     }
+
+    /**
+     * Return header for view grid
+     *
+     * @return string
+     */
+    public function getHeaderHtml()
+    {
+        return '<h3 class="' . $this->getHeaderCssClass() . '">' . $this->escapeHtml($this->getHeaderText()) . '</h3>';
+    }
 //
 //    /**
 //     * Return URL for accept payment action
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
index 098c2b948da..563c529925e 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
@@ -75,6 +75,7 @@ class Mage_Adminhtml_Block_Sales_Shipment_Grid extends Mage_Adminhtml_Block_Widg
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
index 15996b53815..da76d728803 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
@@ -82,7 +82,8 @@ class Mage_Adminhtml_Block_Sales_Transactions_Grid extends Mage_Adminhtml_Block_
         $this->addColumn('increment_id', array(
             'header'    => Mage::helper('sales')->__('Order ID'),
             'index'     => 'increment_id',
-            'type'      => 'text'
+            'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('txn_id', array(
diff --git app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
index 8b4c73db2df..4688fba9ee8 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
@@ -45,10 +45,12 @@ class Mage_Adminhtml_Block_System_Email_Template_Preview extends Mage_Adminhtml_
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
 
-        /* @var $filter Mage_Core_Model_Input_Filter_MaliciousCode */
-        $filter = Mage::getSingleton('core/input_filter_maliciousCode');
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+
         $template->setTemplateText(
-            $filter->filter($template->getTemplateText())
+            $this->maliciousCodeFilter($template->getTemplateText())
         );
 
         Varien_Profiler::start("email_template_proccessing");
diff --git app/code/core/Mage/Adminhtml/Block/Template.php app/code/core/Mage/Adminhtml/Block/Template.php
index bdb4ebe7077..7bd0fada031 100644
--- app/code/core/Mage/Adminhtml/Block/Template.php
+++ app/code/core/Mage/Adminhtml/Block/Template.php
@@ -80,4 +80,15 @@ class Mage_Adminhtml_Block_Template extends Mage_Core_Block_Template
         Mage::dispatchEvent('adminhtml_block_html_before', array('block' => $this));
         return parent::_toHtml();
     }
+
+    /**
+     * Deleting script tags from string
+     *
+     * @param string $html
+     * @return string
+     */
+    public function maliciousCodeFilter($html)
+    {
+        return Mage::getSingleton('core/input_filter_maliciousCode')->filter($html);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
index 34c432b3181..3919a15f337 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
@@ -110,11 +110,12 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract extends
             if ($this->getColumn()->getDir()) {
                 $className = 'sort-arrow-' . $dir;
             }
-            $out = '<a href="#" name="'.$this->getColumn()->getId().'" title="'.$nDir
-                   .'" class="' . $className . '"><span class="sort-title">'.$this->getColumn()->getHeader().'</span></a>';
+            $out = '<a href="#" name="' . $this->getColumn()->getId() . '" title="' . $nDir
+                   . '" class="' . $className . '"><span class="sort-title">'
+                   . $this->escapeHtml($this->getColumn()->getHeader()) . '</span></a>';
         }
         else {
-            $out = $this->getColumn()->getHeader();
+            $out = $this->escapeHtml($this->getColumn()->getHeader());
         }
         return $out;
     }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
index ea55273ec57..5ddb084b5af 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
@@ -35,6 +35,8 @@ class Mage_Adminhtml_Model_System_Config_Backend_Baseurl extends Mage_Core_Model
             $parsedUrl = parse_url($value);
             if (!isset($parsedUrl['scheme']) || !isset($parsedUrl['host'])) {
                 Mage::throwException(Mage::helper('core')->__('The %s you entered is invalid. Please make sure that it follows "http://domain.com/" format.', $this->getFieldConfig()->label));
+            } elseif (('https' != $parsedUrl['scheme']) && ('http' != $parsedUrl['scheme'])) {
+                Mage::throwException(Mage::helper('core')->__('Invalid URL scheme.'));
             }
         }
 
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
index 16969885892..706df496cb9 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
@@ -34,6 +34,27 @@
  */
 class Mage_Adminhtml_Model_System_Config_Backend_Locale extends Mage_Core_Model_Config_Data
 {
+    /**
+     * Validate data before save data
+     *
+     * @return Mage_Core_Model_Abstract
+     * @throws Mage_Core_Exception
+     */
+    protected function _beforeSave()
+    {
+        $allCurrenciesOptions = Mage::getSingleton('adminhtml/system_config_source_locale_currency_all')
+            ->toOptionArray(true);
+
+        $allCurrenciesValues = array_column($allCurrenciesOptions, 'value');
+
+        foreach ($this->getValue() as $currency) {
+            if (!in_array($currency, $allCurrenciesValues)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Currency doesn\'t exist.'));
+            }
+        }
+
+        return parent::_beforeSave();
+    }
 
     /**
      * Enter description here...
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
index 82d550dfb56..67144f1ea71 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
@@ -31,11 +31,19 @@
 class Mage_Adminhtml_Model_System_Config_Backend_Serialized_Array extends Mage_Adminhtml_Model_System_Config_Backend_Serialized
 {
     /**
-     * Unset array element with '__empty' key
+     * Check object existence in incoming data and unset array element with '__empty' key
      *
+     * @throws Mage_Core_Exception
+     * @return void
      */
     protected function _beforeSave()
     {
+        try {
+            Mage::helper('core/unserializeArray')->unserialize(serialize($this->getValue()));
+        } catch (Exception $e) {
+            Mage::throwException(Mage::helper('adminhtml')->__('Serialized data is incorrect'));
+        }
+
         $value = $this->getValue();
         if (is_array($value)) {
             unset($value['__empty']);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
index 0d00eefbd46..4702ec9c614 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
@@ -41,6 +41,17 @@ class Mage_Adminhtml_Catalog_Product_ReviewController extends Mage_Adminhtml_Con
      */
     protected $_publicActions = array('edit');
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions(array('delete', 'massDelete'));
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Catalog'))
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index a60cd1152b9..9d4a2e626d0 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -534,7 +534,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         catch (Mage_Eav_Model_Entity_Attribute_Exception $e) {
             $response->setError(true);
             $response->setAttribute($e->getAttributeCode());
-            $response->setMessage($e->getMessage());
+            $response->setMessage(Mage::helper('core')->escapeHtml($e->getMessage()));
         }
         catch (Mage_Core_Exception $e) {
             $response->setError(true);
diff --git app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
index 6cb4bc904b8..93d05c13745 100644
--- app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
+++ app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
@@ -33,6 +33,17 @@
  */
 class Mage_Adminhtml_Checkout_AgreementController extends Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Sales'))->_title($this->__('Terms and Conditions'));
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index ea0af8d7666..f86fb26c967 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -167,6 +167,11 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
         }
 
         try {
+            $allowedHtmlTags = ['text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->addData($request->getParams())
                 ->setTemplateSubject($request->getParam('subject'))
                 ->setTemplateCode($request->getParam('code'))
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
index adfdca16e7f..95ee6c1e40e 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
@@ -107,6 +107,9 @@ class Mage_Adminhtml_Promo_CatalogController extends Mage_Adminhtml_Controller_A
                 $model = Mage::getModel('catalogrule/rule');
                 Mage::dispatchEvent('adminhtml_controller_catalogrule_prepare_save', array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 if ($id = $this->getRequest()->getParam('rule_id')) {
                     $model->load($id);
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
index be43ae84457..d7a6385ff02 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
@@ -120,7 +120,9 @@ class Mage_Adminhtml_Promo_QuoteController extends Mage_Adminhtml_Controller_Act
                 $model = Mage::getModel('salesrule/rule');
                 Mage::dispatchEvent('adminhtml_controller_salesrule_prepare_save', array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
-
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 $id = $this->getRequest()->getParam('rule_id');
                 if ($id) {
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
index f1f710e5555..0461818c0cd 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
@@ -124,6 +124,13 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
          * Saving order data
          */
         if ($data = $this->getRequest()->getPost('order')) {
+            if (
+                array_key_exists('comment', $data)
+                && array_key_exists('reserved_order_id', $data['comment'])
+            ) {
+                unset($data['comment']['reserved_order_id']);
+            }
+
             $this->_getOrderCreateModel()->importPostData($data);
         }
 
@@ -374,10 +381,20 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
 
     /**
      * Saving quote and create order
+     *
+     * @throws Mage_Core_Exception
      */
     public function saveAction()
     {
         try {
+            $orderData = $this->getRequest()->getPost('order');
+            if (
+                array_key_exists('reserved_order_id', $orderData['comment'])
+                && Mage::helper('adminhtml/sales')->hasTags($orderData['comment']['reserved_order_id'])
+            ) {
+                Mage::throwException($this->__('Invalid order data.'));
+            }
+
             $this->_processData();
             if ($paymentData = $this->getRequest()->getPost('payment')) {
                 $this->_getOrderCreateModel()->setPaymentData($paymentData);
diff --git app/code/core/Mage/Adminhtml/controllers/SitemapController.php app/code/core/Mage/Adminhtml/controllers/SitemapController.php
index e7604e10436..aea2e515c9d 100644
--- app/code/core/Mage/Adminhtml/controllers/SitemapController.php
+++ app/code/core/Mage/Adminhtml/controllers/SitemapController.php
@@ -33,6 +33,11 @@
  */
 class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Maximum sitemap name length
+     */
+    const MAXIMUM_SITEMAP_NAME_LENGTH = 32;
+
     /**
      * Controller predispatch method
      *
@@ -130,6 +135,21 @@ class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
             // init model and set data
             $model = Mage::getModel('sitemap/sitemap');
 
+            if (!empty($data['sitemap_filename']) && !empty($data['sitemap_path'])) {
+                // check filename length
+                if (strlen($data['sitemap_filename']) > self::MAXIMUM_SITEMAP_NAME_LENGTH) {
+                    Mage::getSingleton('adminhtml/session')->addError(
+                        Mage::helper('sitemap')->__(
+                            'Please enter a sitemap name with at most %s characters.',
+                            self::MAXIMUM_SITEMAP_NAME_LENGTH
+                        ));
+                    $this->_redirect('*/*/edit', array(
+                        'sitemap_id' => $this->getRequest()->getParam('sitemap_id')
+                    ));
+                    return;
+                }
+            }
+
             if ($this->getRequest()->getParam('sitemap_id')) {
                 $model ->load($this->getRequest()->getParam('sitemap_id'));
 
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index 43ea1071283..d84192169d0 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
@@ -89,6 +89,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         $this->renderLayout();
     }
 
+    /**
+     * Save action
+     *
+     * @throws Mage_Core_Exception
+     */
     public function saveAction()
     {
         $request = $this->getRequest();
@@ -102,6 +107,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         }
 
         try {
+            $allowedHtmlTags = ['template_text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->setTemplateSubject($request->getParam('template_subject'))
                 ->setTemplateCode($request->getParam('template_code'))
 /*
diff --git app/code/core/Mage/Catalog/Helper/Product.php app/code/core/Mage/Catalog/Helper/Product.php
index d0ece417fac..718cf4072b2 100644
--- app/code/core/Mage/Catalog/Helper/Product.php
+++ app/code/core/Mage/Catalog/Helper/Product.php
@@ -35,6 +35,8 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
     const XML_PATH_PRODUCT_URL_USE_CATEGORY     = 'catalog/seo/product_use_categories';
     const XML_PATH_USE_PRODUCT_CANONICAL_TAG    = 'catalog/seo/product_canonical_tag';
 
+    const DEFAULT_QTY                           = 1;
+
     /**
      * Cache for product rewrite suffix
      *
@@ -259,4 +261,41 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
         }
         return null;
     }
+
+    /**
+     * Get default product value by field name
+     *
+     * @param string $fieldName
+     * @param string $productType
+     * @return int
+     */
+    public function getDefaultProductValue($fieldName, $productType)
+    {
+        $fieldData = $this->getFieldset($fieldName) ? (array) $this->getFieldset($fieldName) : null;
+        if (
+            count($fieldData)
+            && array_key_exists($productType, $fieldData['product_type'])
+            && (bool)$fieldData['use_config']
+        ) {
+            return $fieldData['inventory'];
+        }
+        return self::DEFAULT_QTY;
+    }
+
+    /**
+     * Return array from config by fieldset name and area
+     *
+     * @param null|string $field
+     * @param string $fieldset
+     * @param string $area
+     * @return array|null
+     */
+    public function getFieldset($field = null, $fieldset = 'catalog_product_dataflow', $area = 'admin')
+    {
+        $fieldsetData = Mage::getConfig()->getFieldset($fieldset, $area);
+        if ($fieldsetData) {
+            return $fieldsetData ? $fieldsetData->$field : $fieldsetData;
+        }
+        return $fieldsetData;
+    }
 }
diff --git app/code/core/Mage/Catalog/controllers/Product/CompareController.php app/code/core/Mage/Catalog/controllers/Product/CompareController.php
index 55b93f5f729..c46f519d7f1 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -71,7 +71,11 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
             $this->_redirectReferer();
             return;
         }
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)
+            && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
+        ) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -95,7 +99,8 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function removeAction()
     {
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -154,4 +159,15 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
 
         $this->_redirectReferer();
     }
+
+    /**
+     * Check if product is available
+     *
+     * @param int $productId
+     * @return bool
+     */
+    public function isProductAvailable($productId)
+    {
+        return Mage::getModel('catalog/product')->load($productId)->isAvailable();
+    }
 }
diff --git app/code/core/Mage/Checkout/Model/Session.php app/code/core/Mage/Checkout/Model/Session.php
index 8734551186f..6a466e13f28 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -57,11 +57,18 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             $quote = Mage::getModel('sales/quote')
                 ->setStoreId(Mage::app()->getStore()->getId());
+            $customerSession = Mage::getSingleton('customer/session');
 
             /* @var $quote Mage_Sales_Model_Quote */
             if ($this->getQuoteId()) {
                 $quote->loadActive($this->getQuoteId());
-                if ($quote->getId()) {
+                if (
+                    $quote->getId()
+                    && (
+                        ($customerSession->isLoggedIn() && $customerSession->getId() == $quote->getCustomerId())
+                        || (!$customerSession->isLoggedIn() && !$quote->getCustomerId())
+                    )
+                ) {
                     /**
                      * If current currency code of quote is not equal current currency code of store,
                      * need recalculate totals of quote. It is possible if customer use currency switcher or
@@ -78,15 +85,15 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                         $quote->load($this->getQuoteId());
                     }
                 } else {
+                    $quote->unsetData();
                     $this->setQuoteId(null);
                 }
             }
 
-            $customerSession = Mage::getSingleton('customer/session');
-
             if (!$this->getQuoteId()) {
                 if ($customerSession->isLoggedIn()) {
                     $quote->loadByCustomer($customerSession->getCustomer());
+                    $quote->setCustomer($customerSession->getCustomer());
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index c4c455e4a26..c90c197054c 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -481,7 +481,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
-        if (!$this->_validateFormKey()) {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
             return $this->_redirect('*/*');
         }
 
diff --git app/code/core/Mage/Cms/Helper/Data.php app/code/core/Mage/Cms/Helper/Data.php
index aed32cc8f0d..27628562242 100644
--- app/code/core/Mage/Cms/Helper/Data.php
+++ app/code/core/Mage/Cms/Helper/Data.php
@@ -37,6 +37,7 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
     const XML_NODE_PAGE_TEMPLATE_FILTER     = 'global/cms/page/tempate_filter';
     const XML_NODE_BLOCK_TEMPLATE_FILTER    = 'global/cms/block/tempate_filter';
     const XML_NODE_ALLOWED_STREAM_WRAPPERS  = 'global/cms/allowed_stream_wrappers';
+    const XML_NODE_ALLOWED_MEDIA_EXT_SWF    = 'adminhtml/cms/browser/extensions/media_allowed/swf';
 
     /**
      * Retrieve Template processor for Page Content
@@ -74,4 +75,19 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
 
         return is_array($allowedStreamWrappers) ? $allowedStreamWrappers : array();
     }
+
+    /**
+     * Check is swf file extension disabled
+     *
+     * @return bool
+     */
+    public function isSwfDisabled()
+    {
+        $statusSwf = Mage::getConfig()->getNode(self::XML_NODE_ALLOWED_MEDIA_EXT_SWF);
+        if ($statusSwf instanceof Mage_Core_Model_Config_Element) {
+            $statusSwf = $statusSwf->asArray()[0];
+        }
+
+        return $statusSwf ? false : true;
+    }
 }
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Config.php app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
index 4fad1bfa8b4..e8a3b727a8f 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
@@ -76,7 +76,8 @@ class Mage_Cms_Model_Wysiwyg_Config extends Varien_Object
             'popup_css'                     => Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/dialog.css',
             'content_css'                   => Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/content.css',
             'width'                         => '100%',
-            'plugins'                       => array()
+            'plugins'                       => array(),
+            'media_disable_flash'           => Mage::helper('cms')->isSwfDisabled()
         ));
 
         $config->setData('directives_url_quoted', preg_quote($config->getData('directives_url')));
diff --git app/code/core/Mage/Cms/etc/config.xml app/code/core/Mage/Cms/etc/config.xml
index 96c22853852..29a814d63d4 100644
--- app/code/core/Mage/Cms/etc/config.xml
+++ app/code/core/Mage/Cms/etc/config.xml
@@ -122,7 +122,7 @@
                     </image_allowed>
                     <media_allowed>
                         <flv>1</flv>
-                        <swf>1</swf>
+                        <swf>0</swf>
                         <avi>1</avi>
                         <mov>1</mov>
                         <rm>1</rm>
diff --git app/code/core/Mage/Compiler/Model/Process.php app/code/core/Mage/Compiler/Model/Process.php
index 136968955f4..f76577c0012 100644
--- app/code/core/Mage/Compiler/Model/Process.php
+++ app/code/core/Mage/Compiler/Model/Process.php
@@ -43,6 +43,9 @@ class Mage_Compiler_Model_Process
 
     protected $_controllerFolders = array();
 
+    /** $_collectLibs library list array */
+    protected $_collectLibs = array();
+
     public function __construct($options=array())
     {
         if (isset($options['compile_dir'])) {
@@ -128,6 +131,9 @@ class Mage_Compiler_Model_Process
                 || !in_array(substr($source, strlen($source)-4, 4), array('.php'))) {
                 return $this;
             }
+            if (!$firstIteration && stripos($source, Mage::getBaseDir('lib') . DS) !== false) {
+                $this->_collectLibs[] = $target;
+            }
             copy($source, $target);
         }
         return $this;
@@ -341,6 +347,11 @@ class Mage_Compiler_Model_Process
     {
         $sortedClasses = array();
         foreach ($classes as $className) {
+            /** Skip iteration if this class has already been moved to the includes folder from the lib */
+            if (array_search($this->_includeDir . DS . $className . '.php', $this->_collectLibs)) {
+                continue;
+            }
+
             $implements = array_reverse(class_implements($className));
             foreach ($implements as $class) {
                 if (!in_array($class, $sortedClasses) && !in_array($class, $this->_processedClasses) && strstr($class, '_')) {
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index 81be11aa17c..3a9238faa1f 100644
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -422,4 +422,42 @@ abstract class Mage_Core_Helper_Abstract
         }
         return $arr;
     }
+
+    /**
+     * Check for tags in multidimensional arrays
+     *
+     * @param string|array $data
+     * @param array $arrayKeys keys of the array being checked that are excluded and included in the check
+     * @param bool $skipTags skip transferred array keys, if false then check only them
+     * @return bool
+     */
+    public function hasTags($data, array $arrayKeys = array(), $skipTags = true)
+    {
+        if (is_array($data)) {
+            foreach ($data as $key => $item) {
+                if ($skipTags && in_array($key, $arrayKeys)) {
+                    continue;
+                }
+                if (is_array($item)) {
+                    if ($this->hasTags($item, $arrayKeys, $skipTags)) {
+                        return true;
+                    }
+                } elseif (
+                    (bool)strcmp($item, $this->removeTags($item))
+                    || (bool)strcmp($key, $this->removeTags($key))
+                ) {
+                    if (!$skipTags && !in_array($key, $arrayKeys)) {
+                        continue;
+                    }
+                    return true;
+                }
+            }
+            return false;
+        } elseif (is_string($data)) {
+            if ((bool)strcmp($data, $this->removeTags($data))) {
+                return true;
+            }
+        }
+        return false;
+    }
 }
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index aae48d809ca..318f1f663e1 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -210,7 +210,7 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         }
         mt_srand(10000000*(double)microtime());
         for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
-            $str .= $chars[mt_rand(0, $lc)];
+            $str .= $chars[random_int(0, $lc)];
         }
         return $str;
     }
diff --git app/code/core/Mage/Core/Model/Design/Package.php app/code/core/Mage/Core/Model/Design/Package.php
index 1f23c08f795..e9d3dfe4f93 100644
--- app/code/core/Mage/Core/Model/Design/Package.php
+++ app/code/core/Mage/Core/Model/Design/Package.php
@@ -559,7 +559,12 @@ class Mage_Core_Model_Design_Package
             }
             $configValueSerialized = Mage::getStoreConfig($regexpsConfigPath, $this->getStore());
             if ($configValueSerialized) {
-                $regexps = @unserialize($configValueSerialized);
+                try {
+                    $regexps = Mage::helper('core/unserializeArray')->unserialize($configValueSerialized);
+                } catch (Exception $e) {
+                    Mage::logException($e);
+                }
+
                 if (!empty($regexps)) {
                     foreach ($regexps as $rule) {
                         if (!empty(self::$_regexMatchCache[$rule['regexp']][$_SERVER['HTTP_USER_AGENT']])) {
diff --git app/code/core/Mage/Core/Model/Email/Template/Filter.php app/code/core/Mage/Core/Model/Email/Template/Filter.php
index 65101f4af35..8de1f1f01b4 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -518,4 +518,24 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         }
         return $value;
     }
+
+    /**
+     * Return variable value for var construction
+     *
+     * @param string $value raw parameters
+     * @param string $default default value
+     * @return string
+     */
+    protected function _getVariable($value, $default = '{no_value_defined}')
+    {
+        Mage::register('varProcessing', true);
+        try {
+            $result = parent::_getVariable($value, $default);
+        } catch (Exception $e) {
+            $result = '';
+            Mage::logException($e);
+        }
+        Mage::unregister('varProcessing');
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Observer.php app/code/core/Mage/Core/Model/Observer.php
new file mode 100644
index 00000000000..05342eb32d1
--- /dev/null
+++ app/code/core/Mage/Core/Model/Observer.php
@@ -0,0 +1,51 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+
+
+/**
+ * Core Observer model
+ *
+ * @category   Mage
+ * @package    Mage_Core
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Core_Model_Observer
+{
+    /**
+     * Checks method availability for processing in variable
+     *
+     * @param Varien_Event_Observer $observer
+     * @throws Exception
+     * @return Mage_Core_Model_Observer
+     */
+    public function secureVarProcessing(Varien_Event_Observer $observer)
+    {
+        if (Mage::registry('varProcessing')) {
+            Mage::throwException(Mage::helper('core')->__('Disallowed template variable method.'));
+        }
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 0c6818ec85b..88161154256 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -117,6 +117,24 @@
                 <writer_model>Zend_Log_Writer_Stream</writer_model>
             </core>
         </log>
+        <events>
+            <model_save_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_save_before>
+            <model_delete_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_delete_before>
+        </events>
     </global>
     <frontend>
         <routers>
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index 0adc26777da..e58e18195c6 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -410,3 +410,19 @@ if (!function_exists('hash_equals')) {
         return 0 === $result;
     }
 }
+
+if (version_compare(PHP_VERSION, '7.0.0', '<') && !function_exists('random_int')) {
+    /**
+     * Generates pseudo-random integers
+     *
+     * @param int $min
+     * @param int $max
+     * @return int Returns random integer in the range $min to $max, inclusive.
+     */
+    function random_int($min, $max)
+    {
+        mt_srand();
+
+        return mt_rand($min, $max);
+    }
+}
diff --git app/code/core/Mage/Downloadable/controllers/DownloadController.php app/code/core/Mage/Downloadable/controllers/DownloadController.php
index 4b8deb2a053..ab51aa2a001 100644
--- app/code/core/Mage/Downloadable/controllers/DownloadController.php
+++ app/code/core/Mage/Downloadable/controllers/DownloadController.php
@@ -96,7 +96,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $sampleId = $this->getRequest()->getParam('sample_id', 0);
         $sample = Mage::getModel('downloadable/sample')->load($sampleId);
-        if ($sample->getId()) {
+        if (
+            $sample->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $sample->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($sample->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
@@ -126,7 +131,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $linkId = $this->getRequest()->getParam('link_id', 0);
         $link = Mage::getModel('downloadable/link')->load($linkId);
-        if ($link->getId()) {
+        if (
+            $link->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $link->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($link->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
diff --git app/code/core/Mage/Sendfriend/etc/config.xml app/code/core/Mage/Sendfriend/etc/config.xml
index 24696a204d7..e95e8c83281 100644
--- app/code/core/Mage/Sendfriend/etc/config.xml
+++ app/code/core/Mage/Sendfriend/etc/config.xml
@@ -122,7 +122,7 @@
     <default>
         <sendfriend>
             <email>
-                <enabled>1</enabled>
+                <enabled>0</enabled>
                 <template>sendfriend_email_template</template>
                 <allow_guest>0</allow_guest>
                 <max_recipients>5</max_recipients>
diff --git app/code/core/Mage/Sendfriend/etc/system.xml app/code/core/Mage/Sendfriend/etc/system.xml
index cefb6d28db7..303f12ba511 100644
--- app/code/core/Mage/Sendfriend/etc/system.xml
+++ app/code/core/Mage/Sendfriend/etc/system.xml
@@ -52,6 +52,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
+                            <comment><![CDATA[<strong style="color:red">Warning!</strong> This functionality is vulnerable and can be abused to distribute spam.]]></comment>
                         </enabled>
                         <template translate="label">
                             <label>Select Email Template</label>
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php.orig app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php.orig
deleted file mode 100644
index 63949ced47c..00000000000
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Usps.php.orig
+++ /dev/null
@@ -1,1034 +0,0 @@
-<?php
-/**
- * Magento Enterprise Edition
- *
- * NOTICE OF LICENSE
- *
- * This source file is subject to the Magento Enterprise Edition License
- * that is bundled with this package in the file LICENSE_EE.txt.
- * It is also available through the world-wide-web at this URL:
- * http://www.magentocommerce.com/license/enterprise-edition
- * If you did not receive a copy of the license and are unable to
- * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
- *
- * DISCLAIMER
- *
- * Do not edit or add to this file if you wish to upgrade Magento to newer
- * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
- *
- * @category    Mage
- * @package     Mage_Usa
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://www.magentocommerce.com/license/enterprise-edition
- */
-
-
-/**
- * USPS shipping rates estimation
- *
- * @link       http://www.usps.com/webtools/htm/Development-Guide.htm
- * @category   Mage
- * @package    Mage_Usa
- * @author      Magento Core Team <core@magentocommerce.com>
- */
-class Mage_Usa_Model_Shipping_Carrier_Usps
-    extends Mage_Usa_Model_Shipping_Carrier_Abstract
-    implements Mage_Shipping_Model_Carrier_Interface
-{
-    /**
-     * Destination Zip Code required flag
-     *
-     * @var boolean
-     */
-    protected $_isZipCodeRequired;
-
-    protected $_code = 'usps';
-
-    protected $_request = null;
-
-    protected $_result = null;
-
-    protected $_defaultGatewayUrl = 'http://production.shippingapis.com/ShippingAPI.dll';
-
-    /**
-     * Check is Zip Code Required
-     *
-     * @return boolean
-     */
-    public function isZipCodeRequired()
-    {
-        if (!is_null($this->_isZipCodeRequired)) {
-            return $this->_isZipCodeRequired;
-        }
-
-        return parent::isZipCodeRequired();
-    }
-
-    /**
-     * Processing additional validation to check is carrier applicable.
-     *
-     * @param Mage_Shipping_Model_Rate_Request $request
-     * @return Mage_Shipping_Model_Carrier_Abstract|Mage_Shipping_Model_Rate_Result_Error|boolean
-     */
-    public function proccessAdditionalValidation(Mage_Shipping_Model_Rate_Request $request)
-    {
-        // zip code required for US
-        $this->_isZipCodeRequired = $this->_isUSCountry($request->getDestCountryId());
-
-        return parent::proccessAdditionalValidation($request);
-    }
-
-    public function collectRates(Mage_Shipping_Model_Rate_Request $request)
-    {
-        if (!$this->getConfigFlag('active')) {
-            return false;
-        }
-
-        $this->setRequest($request);
-
-        $this->_result = $this->_getQuotes();
-
-        $this->_updateFreeMethodQuote($request);
-
-        return $this->getResult();
-    }
-
-    public function setRequest(Mage_Shipping_Model_Rate_Request $request)
-    {
-        $this->_request = $request;
-
-        $r = new Varien_Object();
-
-        if ($request->getLimitMethod()) {
-            $r->setService($request->getLimitMethod());
-        } else {
-            $r->setService('ALL');
-        }
-
-        if ($request->getUspsUserid()) {
-            $userId = $request->getUspsUserid();
-        } else {
-            $userId = $this->getConfigData('userid');
-        }
-        $r->setUserId($userId);
-
-        if ($request->getUspsContainer()) {
-            $container = $request->getUspsContainer();
-        } else {
-            $container = $this->getConfigData('container');
-        }
-        $r->setContainer($container);
-
-        if ($request->getUspsSize()) {
-            $size = $request->getUspsSize();
-        } else {
-            $size = $this->getConfigData('size');
-        }
-        $r->setSize($size);
-
-        if ($request->getUspsMachinable()) {
-            $machinable = $request->getUspsMachinable();
-        } else {
-            $machinable = $this->getConfigData('machinable');
-        }
-        $r->setMachinable($machinable);
-
-        if ($request->getOrigPostcode()) {
-            $r->setOrigPostal($request->getOrigPostcode());
-        } else {
-            $r->setOrigPostal(Mage::getStoreConfig('shipping/origin/postcode'));
-        }
-
-        if ($request->getDestCountryId()) {
-            $destCountry = $request->getDestCountryId();
-        } else {
-            $destCountry = self::USA_COUNTRY_ID;
-        }
-
-        $r->setDestCountryId($destCountry);
-
-        if (!$this->_isUSCountry($destCountry)) {
-            $r->setDestCountryName($this->_getCountryName($destCountry));
-        }
-
-        if ($request->getDestPostcode()) {
-            $r->setDestPostal($request->getDestPostcode());
-        }
-
-        $weight = $this->getTotalNumOfBoxes($request->getPackageWeight());
-        $r->setWeightPounds(floor($weight));
-        $r->setWeightOunces(round(($weight - floor($weight)) * 16, 1));
-        if ($request->getFreeMethodWeight()!=$request->getPackageWeight()) {
-            $r->setFreeMethodWeight($request->getFreeMethodWeight());
-        }
-
-        $r->setValue($request->getPackageValue());
-        $r->setValueWithDiscount($request->getPackageValueWithDiscount());
-
-        $this->_rawRequest = $r;
-
-        return $this;
-    }
-
-    public function getResult()
-    {
-       return $this->_result;
-    }
-
-    protected function _getQuotes()
-    {
-        return $this->_getXmlQuotes();
-    }
-
-    protected function _setFreeMethodRequest($freeMethod)
-    {
-        $r = $this->_rawRequest;
-
-        $weight = $this->getTotalNumOfBoxes($r->getFreeMethodWeight());
-        $r->setWeightPounds(floor($weight));
-        $r->setWeightOunces(round(($weight-floor($weight))*16, 1));
-        $r->setService($freeMethod);
-    }
-
-    protected function _getXmlQuotes()
-    {
-        $r = $this->_rawRequest;
-        if ($this->_isUSCountry($r->getDestCountryId())) {
-            $xml = new SimpleXMLElement('<?xml version = "1.0" encoding = "UTF-8"?><RateV3Request/>');
-
-            $xml->addAttribute('USERID', $r->getUserId());
-
-            $package = $xml->addChild('Package');
-                $package->addAttribute('ID', 0);
-                $service = $this->getCode('service_to_code', $r->getService());
-                if (!$service) {
-                    $service = $r->getService();
-                }
-                $package->addChild('Service', $service);
-
-                // no matter Letter, Flat or Parcel, use Parcel
-                if ($r->getService() == 'FIRST CLASS') {
-                    $package->addChild('FirstClassMailType', 'PARCEL');
-                }
-                if ($r->getService() == 'FIRST CLASS COMMERCIAL') {
-                    $package->addChild('FirstClassMailType', 'PACKAGE SERVICE');
-                }
-
-                $package->addChild('ZipOrigination', $r->getOrigPostal());
-                //only 5 chars available
-                $package->addChild('ZipDestination', substr($r->getDestPostal(),0,5));
-                $package->addChild('Pounds', $r->getWeightPounds());
-                $package->addChild('Ounces', $r->getWeightOunces());
-//                $package->addChild('Pounds', '0');
-//                $package->addChild('Ounces', '3');
-
-                // Because some methods don't accept VARIABLE and (NON)RECTANGULAR containers
-                if (strtoupper($r->getContainer()) == 'FLAT RATE ENVELOPE' || strtoupper($r->getContainer()) == 'FLAT RATE BOX') {
-                    $package->addChild('Container', $r->getContainer());
-                }
-
-                $package->addChild('Size', $r->getSize());
-                $package->addChild('Machinable', $r->getMachinable());
-
-            $api = 'RateV3';
-            $request = $xml->asXML();
-
-        } else {
-            $xml = new SimpleXMLElement('<?xml version = "1.0" encoding = "UTF-8"?><IntlRateRequest/>');
-
-            $xml->addAttribute('USERID', $r->getUserId());
-
-            $package = $xml->addChild('Package');
-                $package->addAttribute('ID', 0);
-                $package->addChild('Pounds', $r->getWeightPounds());
-                $package->addChild('Ounces', $r->getWeightOunces());
-                $package->addChild('MailType', 'Package');
-                $package->addChild('ValueOfContents', $r->getValue());
-                $package->addChild('Country', $r->getDestCountryName());
-
-            $api = 'IntlRate';
-            $request = $xml->asXML();
-        }
-
-        $responseBody = $this->_getCachedQuotes($request);
-        if ($responseBody === null) {
-            $debugData = array('request' => $request);
-            try {
-                $url = $this->getConfigData('gateway_url');
-                if (!$url) {
-                    $url = $this->_defaultGatewayUrl;
-                }
-                $client = new Zend_Http_Client();
-                $client->setUri($url);
-                $client->setConfig(array('maxredirects'=>0, 'timeout'=>30));
-                $client->setParameterGet('API', $api);
-                $client->setParameterGet('XML', $request);
-                $response = $client->request();
-                $responseBody = $response->getBody();
-
-                $debugData['result'] = $responseBody;
-                $this->_setCachedQuotes($request, $responseBody);
-            }
-            catch (Exception $e) {
-                $debugData['result'] = array('error' => $e->getMessage(), 'code' => $e->getCode());
-                $responseBody = '';
-            }
-            $this->_debug($debugData);
-        }
-        return $this->_parseXmlResponse($responseBody);;
-    }
-
-    protected function _parseXmlResponse($response)
-    {
-        $costArr = array();
-        $priceArr = array();
-        $errorTitle = 'Unable to retrieve quotes';
-        if (strlen(trim($response))>0) {
-            if (strpos(trim($response), '<?xml')===0) {
-                if (preg_match('#<\?xml version="1.0"\?>#', $response)) {
-                    $response = str_replace('<?xml version="1.0"?>', '<?xml version="1.0" encoding="ISO-8859-1"?>', $response);
-                }
-
-                $xml = simplexml_load_string($response);
-                if (is_object($xml)) {
-                    $r = $this->_rawRequest;
-                    $allowedMethods = explode(',', $this->getConfigData('allowed_methods'));
-                    $serviceCodeToActualNameMap = array();
-                    /**
-                     * US Rates
-                     */
-                    if ($this->_isUSCountry($r->getDestCountryId())) {
-                        if (is_object($xml->Package) && is_object($xml->Package->Postage)) {
-                            foreach ($xml->Package->Postage as $postage) {
-                                $serviceName = $this->_filterServiceName((string)$postage->MailService);
-                                $_serviceCode = $this->getCode('method_to_code', $serviceName);
-                                $serviceCode = $_serviceCode ? $_serviceCode : (string)$postage->attributes()->CLASSID;
-                                $serviceCodeToActualNameMap[$serviceCode] = $serviceName;
-                                if (in_array($serviceCode, $allowedMethods)) {
-                                    $costArr[$serviceCode] = (string)$postage->Rate;
-                                    $priceArr[$serviceCode] = $this->getMethodPrice(
-                                        (string)$postage->Rate,
-                                        $serviceCode
-                                    );
-                                }
-                            }
-                            asort($priceArr);
-                        }
-                    }
-                    /**
-                     * International Rates
-                     */
-                    else {
-                        if (is_object($xml->Package) && is_object($xml->Package->Service)) {
-                            foreach ($xml->Package->Service as $service) {
-                                $serviceName = $this->_filterServiceName((string)$service->SvcDescription);
-                                $serviceCode = 'INT_' . (string)$service->attributes()->ID;
-                                $serviceCodeToActualNameMap[$serviceCode] = $serviceName;
-                                if (in_array($serviceCode, $allowedMethods)) {
-                                    $costArr[$serviceCode] = (string)$service->Postage;
-                                    $priceArr[$serviceCode] = $this->getMethodPrice(
-                                        (string)$service->Postage,
-                                        $serviceCode
-                                    );
-                                }
-                            }
-                            asort($priceArr);
-                        }
-                    }
-                }
-            }
-        }
-
-        $result = Mage::getModel('shipping/rate_result');
-        $defaults = $this->getDefaults();
-        if (empty($priceArr)) {
-            $error = Mage::getModel('shipping/rate_result_error');
-            $error->setCarrier('usps');
-            $error->setCarrierTitle($this->getConfigData('title'));
-            $error->setErrorMessage($this->getConfigData('specificerrmsg'));
-            $result->append($error);
-        } else {
-            foreach ($priceArr as $method => $price) {
-                $rate = Mage::getModel('shipping/rate_result_method');
-                $rate->setCarrier('usps');
-                $rate->setCarrierTitle($this->getConfigData('title'));
-                $rate->setMethod($method);
-                $rate->setMethodTitle(
-                    isset($serviceCodeToActualNameMap[$method])
-                        ? $serviceCodeToActualNameMap[$method]
-                        : $this->getCode('method', $method)
-                );
-                $rate->setCost($costArr[$method]);
-                $rate->setPrice($price);
-                $result->append($rate);
-            }
-        }
-        return $result;
-    }
-
-    public function getCode($type, $code = '')
-    {
-        $codes = array(
-            'method' => array(
-                '0_FCLE' => Mage::helper('usa')->__('First-Class Mail Large Envelope'),
-                '0_FCL'  => Mage::helper('usa')->__('First-Class Mail Letter'),
-                '0_FCP'  => Mage::helper('usa')->__('First-Class Mail Parcel'),
-                '0_FCPC' => Mage::helper('usa')->__('First-Class Mail Postcards'),
-                '1'      => Mage::helper('usa')->__('Priority Mail'),
-                '2'      => Mage::helper('usa')->__('Priority Mail Express Hold For Pickup'),
-                '3'      => Mage::helper('usa')->__('Priority Mail Express'),
-                '4'      => Mage::helper('usa')->__('Retail Ground'),
-                '6'      => Mage::helper('usa')->__('Media Mail Parcel'),
-                '7'      => Mage::helper('usa')->__('Library Mail Parcel'),
-                '13'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope'),
-                '15'     => Mage::helper('usa')->__('First-Class Mail Large Postcards'),
-                '16'     => Mage::helper('usa')->__('Priority Mail Flat Rate Envelope'),
-                '17'     => Mage::helper('usa')->__('Priority Mail Medium Flat Rate Box'),
-                '22'     => Mage::helper('usa')->__('Priority Mail Large Flat Rate Box'),
-                '23'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery'),
-                '25'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Envelope'),
-                '27'     => Mage::helper('usa')->__('Priority Mail Express Flat Rate Envelope Hold For Pickup'),
-                '28'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Box'),
-                '29'     => Mage::helper('usa')->__('Priority Mail Padded Flat Rate Envelope'),
-                '30'     => Mage::helper('usa')->__('Priority Mail Express Legal Flat Rate Envelope'),
-                '31'     => Mage::helper('usa')->__('Priority Mail Express Legal Flat Rate Envelope Hold For Pickup'),
-                '32'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Legal Flat Rate Envelope'),
-                '33'     => Mage::helper('usa')->__('Priority Mail Hold For Pickup'),
-                '34'     => Mage::helper('usa')->__('Priority Mail Large Flat Rate Box Hold For Pickup'),
-                '35'     => Mage::helper('usa')->__('Priority Mail Medium Flat Rate Box Hold For Pickup'),
-                '36'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Box Hold For Pickup'),
-                '37'     => Mage::helper('usa')->__('Priority Mail Flat Rate Envelope Hold For Pickup'),
-                '38'     => Mage::helper('usa')->__('Priority Mail Gift Card Flat Rate Envelope'),
-                '39'     => Mage::helper('usa')->__('Priority Mail Gift Card Flat Rate Envelope Hold For Pickup'),
-                '40'     => Mage::helper('usa')->__('Priority Mail Window Flat Rate Envelope'),
-                '41'     => Mage::helper('usa')->__('Priority Mail Window Flat Rate Envelope Hold For Pickup'),
-                '42'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Envelope'),
-                '43'     => Mage::helper('usa')->__('Priority Mail Small Flat Rate Envelope Hold For Pickup'),
-                '44'     => Mage::helper('usa')->__('Priority Mail Legal Flat Rate Envelope'),
-                '45'     => Mage::helper('usa')->__('Priority Mail Legal Flat Rate Envelope Hold For Pickup'),
-                '46'     => Mage::helper('usa')->__('Priority Mail Padded Flat Rate Envelope Hold For Pickup'),
-                '47'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box A'),
-                '48'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box A Hold For Pickup'),
-                '49'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box B'),
-                '50'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box B Hold For Pickup'),
-                '53'     => Mage::helper('usa')->__('First-Class Package Service Hold For Pickup'),
-                '57'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Flat Rate Boxes'),
-                '58'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box C'),
-                '59'     => Mage::helper('usa')->__('Priority Mail Regional Rate Box C Hold For Pickup'),
-                '61'     => Mage::helper('usa')->__('First-Class Package Service'),
-                '62'     => Mage::helper('usa')->__('Priority Mail Express Padded Flat Rate Envelope'),
-                '63'     => Mage::helper('usa')->__('Priority Mail Express Padded Flat Rate Envelope Hold For Pickup'),
-                '64'     => Mage::helper('usa')->__('Priority Mail Express Sunday/Holiday Delivery Padded Flat Rate Envelope'),
-                'INT_1'  => Mage::helper('usa')->__('Priority Mail Express International'),
-                'INT_2'  => Mage::helper('usa')->__('Priority Mail International'),
-                'INT_4'  => Mage::helper('usa')->__('Global Express Guaranteed (GXG)'),
-                'INT_5'  => Mage::helper('usa')->__('Global Express Guaranteed Document'),
-                'INT_6'  => Mage::helper('usa')->__('Global Express Guaranteed Non-Document Rectangular'),
-                'INT_7'  => Mage::helper('usa')->__('Global Express Guaranteed Non-Document Non-Rectangular'),
-                'INT_8'  => Mage::helper('usa')->__('Priority Mail International Flat Rate Envelope'),
-                'INT_9'  => Mage::helper('usa')->__('Priority Mail International Medium Flat Rate Box'),
-                'INT_10' => Mage::helper('usa')->__('Priority Mail Express International Flat Rate Envelope'),
-                'INT_11' => Mage::helper('usa')->__('Priority Mail International Large Flat Rate Box'),
-                'INT_12' => Mage::helper('usa')->__('USPS GXG Envelopes'),
-                'INT_13' => Mage::helper('usa')->__('First-Class Mail International Letter'),
-                'INT_14' => Mage::helper('usa')->__('First-Class Mail International Large Envelope'),
-                'INT_15' => Mage::helper('usa')->__('First-Class Package International Service'),
-                'INT_16' => Mage::helper('usa')->__('Priority Mail International Small Flat Rate Box'),
-                'INT_17' => Mage::helper('usa')->__('Priority Mail Express International Legal Flat Rate Envelope'),
-                'INT_18' => Mage::helper('usa')->__('Priority Mail International Gift Card Flat Rate Envelope'),
-                'INT_19' => Mage::helper('usa')->__('Priority Mail International Window Flat Rate Envelope'),
-                'INT_20' => Mage::helper('usa')->__('Priority Mail International Small Flat Rate Envelope'),
-                'INT_21' => Mage::helper('usa')->__('First-Class Mail International Postcard'),
-                'INT_22' => Mage::helper('usa')->__('Priority Mail International Legal Flat Rate Envelope'),
-                'INT_23' => Mage::helper('usa')->__('Priority Mail International Padded Flat Rate Envelope'),
-                'INT_24' => Mage::helper('usa')->__('Priority Mail International DVD Flat Rate priced box'),
-                'INT_25' => Mage::helper('usa')->__('Priority Mail International Large Video Flat Rate priced box'),
-                'INT_27' => Mage::helper('usa')->__('Priority Mail Express International Padded Flat Rate Envelope'),
-            ),
-
-            'service_to_code' => array(
-                '0_FCLE' => 'First Class',
-                '0_FCL'  => 'First Class',
-                '0_FCP'  => 'First Class',
-                '0_FCPC' => 'First Class',
-                '1'      => 'Priority',
-                '2'      => 'Priority Express',
-                '3'      => 'Priority Express',
-                '4'      => 'Retail Ground',
-                '6'      => 'Media',
-                '7'      => 'Library',
-                '13'     => 'Priority Express',
-                '15'     => 'First Class',
-                '16'     => 'Priority',
-                '17'     => 'Priority',
-                '22'     => 'Priority',
-                '23'     => 'Priority Express',
-                '25'     => 'Priority Express',
-                '27'     => 'Priority Express',
-                '28'     => 'Priority',
-                '29'     => 'Priority',
-                '30'     => 'Priority Express',
-                '31'     => 'Priority Express',
-                '32'     => 'Priority Express',
-                '33'     => 'Priority',
-                '34'     => 'Priority',
-                '35'     => 'Priority',
-                '36'     => 'Priority',
-                '37'     => 'Priority',
-                '38'     => 'Priority',
-                '39'     => 'Priority',
-                '40'     => 'Priority',
-                '41'     => 'Priority',
-                '42'     => 'Priority',
-                '43'     => 'Priority',
-                '44'     => 'Priority',
-                '45'     => 'Priority',
-                '46'     => 'Priority',
-                '47'     => 'Priority',
-                '48'     => 'Priority',
-                '49'     => 'Priority',
-                '50'     => 'Priority',
-                '53'     => 'First Class',
-                '57'     => 'Priority Express',
-                '58'     => 'Priority',
-                '59'     => 'Priority',
-                '61'     => 'First Class',
-                '62'     => 'Priority Express',
-                '63'     => 'Priority Express',
-                '64'     => 'Priority Express',
-                'INT_1'  => 'Priority Express',
-                'INT_2'  => 'Priority',
-                'INT_4'  => 'Priority Express',
-                'INT_5'  => 'Priority Express',
-                'INT_6'  => 'Priority Express',
-                'INT_7'  => 'Priority Express',
-                'INT_8'  => 'Priority',
-                'INT_9'  => 'Priority',
-                'INT_10' => 'Priority Express',
-                'INT_11' => 'Priority',
-                'INT_12' => 'Priority Express',
-                'INT_13' => 'First Class',
-                'INT_14' => 'First Class',
-                'INT_15' => 'First Class',
-                'INT_16' => 'Priority',
-                'INT_17' => 'Priority',
-                'INT_18' => 'Priority',
-                'INT_19' => 'Priority',
-                'INT_20' => 'Priority',
-                'INT_21' => 'First Class',
-                'INT_22' => 'Priority',
-                'INT_23' => 'Priority',
-                'INT_24' => 'Priority',
-                'INT_25' => 'Priority',
-                'INT_27' => 'Priority Express',
-            ),
-
-            // Added because USPS has different services but with same CLASSID value, which is "0"
-            'method_to_code' => array(
-                'First-Class Mail Large Envelope' => '0_FCLE',
-                'First-Class Mail Letter'         => '0_FCL',
-                'First-Class Mail Parcel'         => '0_FCP',
-            ),
-
-            'first_class_mail_type'=>array(
-                'LETTER'      => Mage::helper('usa')->__('Letter'),
-                'FLAT'        => Mage::helper('usa')->__('Flat'),
-                'PARCEL'      => Mage::helper('usa')->__('Parcel'),
-            ),
-
-            'container'=>array(
-                'VARIABLE'           => Mage::helper('usa')->__('Variable'),
-                'FLAT RATE ENVELOPE' => Mage::helper('usa')->__('Flat-Rate Envelope'),
-                'FLAT RATE BOX'      => Mage::helper('usa')->__('Flat-Rate Box'),
-                'RECTANGULAR'        => Mage::helper('usa')->__('Rectangular'),
-                'NONRECTANGULAR'     => Mage::helper('usa')->__('Non-rectangular'),
-            ),
-
-            'size'=>array(
-                'REGULAR'     => Mage::helper('usa')->__('Regular'),
-                'LARGE'       => Mage::helper('usa')->__('Large'),
-                'OVERSIZE'    => Mage::helper('usa')->__('Oversize'),
-            ),
-
-            'machinable'=>array(
-                'true'        => Mage::helper('usa')->__('Yes'),
-                'false'       => Mage::helper('usa')->__('No'),
-            ),
-
-        );
-
-        if (!isset($codes[$type])) {
-//            throw Mage::exception('Mage_Shipping', Mage::helper('usa')->__('Invalid USPS XML code type: %s', $type));
-            return false;
-        } elseif (''===$code) {
-            return $codes[$type];
-        }
-
-        if (!isset($codes[$type][$code])) {
-//            throw Mage::exception('Mage_Shipping', Mage::helper('usa')->__('Invalid USPS XML code for type %s: %s', $type, $code));
-            return false;
-        } else {
-            return $codes[$type][$code];
-        }
-    }
-
-    /**
-     * Get tracking
-     *
-     * @param mixed $trackingData
-     * @return mixed
-     */
-    public function getTracking($trackingData)
-    {
-        $this->setTrackingRequest();
-
-        if (!is_array($trackingData)) {
-            $trackingData = array($trackingData);
-        }
-
-        $this->_getXmlTracking($trackingData);
-
-        return $this->_result;
-    }
-
-    protected function setTrackingRequest()
-    {
-        $r = new Varien_Object();
-
-        $userId = $this->getConfigData('userid');
-        $r->setUserId($userId);
-
-        $this->_rawTrackRequest = $r;
-
-    }
-
-    /**
-     * Send request for tracking
-     *
-     * @param array $trackingData
-     */
-    protected function _getXmlTracking($trackingData)
-    {
-         $r = $this->_rawTrackRequest;
-
-         foreach ($trackingData as $tracking){
-             $xml = new SimpleXMLElement('<?xml version = "1.0" encoding = "UTF-8"?><TrackRequest/>');
-             $xml->addAttribute('USERID', $r->getUserId());
-
-
-             $trackid = $xml->addChild('TrackID');
-             $trackid->addAttribute('ID',$tracking);
-
-             $api = 'TrackV2';
-             $request = $xml->asXML();
-             $debugData = array('request' => $request);
-
-             try {
-                $url = $this->getConfigData('gateway_url');
-                if (!$url) {
-                    $url = $this->_defaultGatewayUrl;
-                }
-                $client = new Zend_Http_Client();
-                $client->setUri($url);
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
-                $client->setParameterGet('API', $api);
-                $client->setParameterGet('XML', $request);
-                $response = $client->request();
-                $responseBody = $response->getBody();
-                $debugData['result'] = $responseBody;
-            }
-            catch (Exception $e) {
-                $debugData['result'] = array('error' => $e->getMessage(), 'code' => $e->getCode());
-                $responseBody = '';
-            }
-
-            $this->_debug($debugData);
-            $this->_parseXmlTrackingResponse($tracking, $responseBody);
-         }
-    }
-
-    /**
-     * Parse xml tracking response
-     *
-     * @param array $trackingValue
-     * @param string $response
-     * @return null
-     */
-    protected function _parseXmlTrackingResponse($trackingValue, $response)
-    {
-        $errorTitle = 'Unable to retrieve tracking';
-        $resultArr=array();
-        if (strlen(trim($response))>0) {
-            if (strpos(trim($response), '<?xml')===0) {
-                $xml = simplexml_load_string($response);
-                if (is_object($xml)) {
-                    if (isset($xml->Number) && isset($xml->Description) && (string)$xml->Description!='') {
-                        $errorTitle = (string)$xml->Description;
-                    } elseif (isset($xml->TrackInfo) && isset($xml->TrackInfo->Error) && isset($xml->TrackInfo->Error->Description) && (string)$xml->TrackInfo->Error->Description!='') {
-                        $errorTitle = (string)$xml->TrackInfo->Error->Description;
-                    } else {
-                        $errorTitle = 'Unknown error';
-                    }
-
-                    if(isset($xml->TrackInfo) && isset($xml->TrackInfo->TrackSummary)){
-                       $resultArr['tracksummary'] = (string)$xml->TrackInfo->TrackSummary;
-
-                    }
-                }
-            }
-        }
-
-        if(!$this->_result){
-            $this->_result = Mage::getModel('shipping/tracking_result');
-        }
-
-        if ($resultArr) {
-             $tracking = Mage::getModel('shipping/tracking_result_status');
-             $tracking->setCarrier('usps');
-             $tracking->setCarrierTitle($this->getConfigData('title'));
-             $tracking->setTracking($trackingValue);
-             $tracking->setTrackSummary($resultArr['tracksummary']);
-             $this->_result->append($tracking);
-         } else {
-            $error = Mage::getModel('shipping/tracking_result_error');
-            $error->setCarrier('usps');
-            $error->setCarrierTitle($this->getConfigData('title'));
-            $error->setTracking($trackingValue);
-            $error->setErrorMessage($errorTitle);
-            $this->_result->append($error);
-         }
-    }
-
-    public function getResponse()
-    {
-        $statuses = '';
-        if ($this->_result instanceof Mage_Shipping_Model_Tracking_Result){
-            if ($trackingData = $this->_result->getAllTrackings()) {
-                foreach ($trackingData as $tracking){
-                    if($data = $tracking->getAllData()){
-                        if (!empty($data['track_summary'])) {
-                            $statuses .= Mage::helper('usa')->__($data['track_summary']);
-                        } else {
-                            $statuses .= Mage::helper('usa')->__('Empty response');
-                        }
-                    }
-                }
-            }
-        }
-        if (empty($statuses)) {
-            $statuses = Mage::helper('usa')->__('Empty response');
-        }
-        return $statuses;
-    }
-
-    /**
-     * Get allowed shipping methods
-     *
-     * @return array
-     */
-    public function getAllowedMethods()
-    {
-        $allowed = explode(',', $this->getConfigData('allowed_methods'));
-        $arr = array();
-        foreach ($allowed as $k) {
-            $arr[$k] = $this->getCode('method', $k);
-        }
-        return $arr;
-    }
-
-    /**
-     * Check is Сoutry U.S. Possessions and Trust Territories
-     *
-     * @param string $countyId
-     * @return boolean
-     */
-    protected function _isUSCountry($countyId)
-    {
-        switch ($countyId) {
-            case 'AS': // Samoa American
-            case 'GU': // Guam
-            case 'MP': // Northern Mariana Islands
-            case 'PW': // Palau
-            case 'PR': // Puerto Rico
-            case 'VI': // Virgin Islands US
-            case 'US'; // United States
-                return true;
-        }
-
-        return false;
-    }
-
-    /**
-     * Return USPS county name by country ISO 3166-1-alpha-2 code
-     * Return false for unknown countries
-     *
-     * @param string $countryId
-     * @return string|false
-     */
-    protected function _getCountryName($countryId)
-    {
-        $countries = array (
-          'AD' => 'Andorra',
-          'AE' => 'United Arab Emirates',
-          'AF' => 'Afghanistan',
-          'AG' => 'Antigua and Barbuda',
-          'AI' => 'Anguilla',
-          'AL' => 'Albania',
-          'AM' => 'Armenia',
-          'AN' => 'Netherlands Antilles',
-          'AO' => 'Angola',
-          'AR' => 'Argentina',
-          'AT' => 'Austria',
-          'AU' => 'Australia',
-          'AW' => 'Aruba',
-          'AX' => 'Aland Island (Finland)',
-          'AZ' => 'Azerbaijan',
-          'BA' => 'Bosnia-Herzegovina',
-          'BB' => 'Barbados',
-          'BD' => 'Bangladesh',
-          'BE' => 'Belgium',
-          'BF' => 'Burkina Faso',
-          'BG' => 'Bulgaria',
-          'BH' => 'Bahrain',
-          'BI' => 'Burundi',
-          'BJ' => 'Benin',
-          'BM' => 'Bermuda',
-          'BN' => 'Brunei Darussalam',
-          'BO' => 'Bolivia',
-          'BR' => 'Brazil',
-          'BS' => 'Bahamas',
-          'BT' => 'Bhutan',
-          'BW' => 'Botswana',
-          'BY' => 'Belarus',
-          'BZ' => 'Belize',
-          'CA' => 'Canada',
-          'CC' => 'Cocos Island (Australia)',
-          'CD' => 'Congo, Democratic Republic of the',
-          'CF' => 'Central African Republic',
-          'CG' => 'Congo, Republic of the',
-          'CH' => 'Switzerland',
-          'CI' => 'Cote d Ivoire (Ivory Coast)',
-          'CK' => 'Cook Islands (New Zealand)',
-          'CL' => 'Chile',
-          'CM' => 'Cameroon',
-          'CN' => 'China',
-          'CO' => 'Colombia',
-          'CR' => 'Costa Rica',
-          'CU' => 'Cuba',
-          'CV' => 'Cape Verde',
-          'CX' => 'Christmas Island (Australia)',
-          'CY' => 'Cyprus',
-          'CZ' => 'Czech Republic',
-          'DE' => 'Germany',
-          'DJ' => 'Djibouti',
-          'DK' => 'Denmark',
-          'DM' => 'Dominica',
-          'DO' => 'Dominican Republic',
-          'DZ' => 'Algeria',
-          'EC' => 'Ecuador',
-          'EE' => 'Estonia',
-          'EG' => 'Egypt',
-          'ER' => 'Eritrea',
-          'ES' => 'Spain',
-          'ET' => 'Ethiopia',
-          'FI' => 'Finland',
-          'FJ' => 'Fiji',
-          'FK' => 'Falkland Islands',
-          'FM' => 'Micronesia, Federated States of',
-          'FO' => 'Faroe Islands',
-          'FR' => 'France',
-          'GA' => 'Gabon',
-          'GB' => 'Great Britain and Northern Ireland',
-          'GD' => 'Grenada',
-          'GE' => 'Georgia, Republic of',
-          'GF' => 'French Guiana',
-          'GH' => 'Ghana',
-          'GI' => 'Gibraltar',
-          'GL' => 'Greenland',
-          'GM' => 'Gambia',
-          'GN' => 'Guinea',
-          'GP' => 'Guadeloupe',
-          'GQ' => 'Equatorial Guinea',
-          'GR' => 'Greece',
-          'GS' => 'South Georgia (Falkland Islands)',
-          'GT' => 'Guatemala',
-          'GW' => 'Guinea-Bissau',
-          'GY' => 'Guyana',
-          'HK' => 'Hong Kong',
-          'HN' => 'Honduras',
-          'HR' => 'Croatia',
-          'HT' => 'Haiti',
-          'HU' => 'Hungary',
-          'ID' => 'Indonesia',
-          'IE' => 'Ireland',
-          'IL' => 'Israel',
-          'IN' => 'India',
-          'IQ' => 'Iraq',
-          'IR' => 'Iran',
-          'IS' => 'Iceland',
-          'IT' => 'Italy',
-          'JM' => 'Jamaica',
-          'JO' => 'Jordan',
-          'JP' => 'Japan',
-          'KE' => 'Kenya',
-          'KG' => 'Kyrgyzstan',
-          'KH' => 'Cambodia',
-          'KI' => 'Kiribati',
-          'KM' => 'Comoros',
-          'KN' => 'Saint Kitts (St. Christopher and Nevis)',
-          'KP' => 'North Korea (Korea, Democratic People\'s Republic of)',
-          'KR' => 'South Korea (Korea, Republic of)',
-          'KW' => 'Kuwait',
-          'KY' => 'Cayman Islands',
-          'KZ' => 'Kazakhstan',
-          'LA' => 'Laos',
-          'LB' => 'Lebanon',
-          'LC' => 'Saint Lucia',
-          'LI' => 'Liechtenstein',
-          'LK' => 'Sri Lanka',
-          'LR' => 'Liberia',
-          'LS' => 'Lesotho',
-          'LT' => 'Lithuania',
-          'LU' => 'Luxembourg',
-          'LV' => 'Latvia',
-          'LY' => 'Libya',
-          'MA' => 'Morocco',
-          'MC' => 'Monaco (France)',
-          'MD' => 'Moldova',
-          'MG' => 'Madagascar',
-          'MK' => 'Macedonia, Republic of',
-          'ML' => 'Mali',
-          'MM' => 'Burma',
-          'MN' => 'Mongolia',
-          'MO' => 'Macao',
-          'MQ' => 'Martinique',
-          'MR' => 'Mauritania',
-          'MS' => 'Montserrat',
-          'MT' => 'Malta',
-          'MU' => 'Mauritius',
-          'MV' => 'Maldives',
-          'MW' => 'Malawi',
-          'MX' => 'Mexico',
-          'MY' => 'Malaysia',
-          'MZ' => 'Mozambique',
-          'NA' => 'Namibia',
-          'NC' => 'New Caledonia',
-          'NE' => 'Niger',
-          'NG' => 'Nigeria',
-          'NI' => 'Nicaragua',
-          'NL' => 'Netherlands',
-          'NO' => 'Norway',
-          'NP' => 'Nepal',
-          'NR' => 'Nauru',
-          'NZ' => 'New Zealand',
-          'OM' => 'Oman',
-          'PA' => 'Panama',
-          'PE' => 'Peru',
-          'PF' => 'French Polynesia',
-          'PG' => 'Papua New Guinea',
-          'PH' => 'Philippines',
-          'PK' => 'Pakistan',
-          'PL' => 'Poland',
-          'PM' => 'Saint Pierre and Miquelon',
-          'PN' => 'Pitcairn Island',
-          'PT' => 'Portugal',
-          'PY' => 'Paraguay',
-          'QA' => 'Qatar',
-          'RE' => 'Reunion',
-          'RO' => 'Romania',
-          'RS' => 'Serbia',
-          'RU' => 'Russia',
-          'RW' => 'Rwanda',
-          'SA' => 'Saudi Arabia',
-          'SB' => 'Solomon Islands',
-          'SC' => 'Seychelles',
-          'SD' => 'Sudan',
-          'SE' => 'Sweden',
-          'SG' => 'Singapore',
-          'SH' => 'Saint Helena',
-          'SI' => 'Slovenia',
-          'SK' => 'Slovak Republic',
-          'SL' => 'Sierra Leone',
-          'SM' => 'San Marino',
-          'SN' => 'Senegal',
-          'SO' => 'Somalia',
-          'SR' => 'Suriname',
-          'ST' => 'Sao Tome and Principe',
-          'SV' => 'El Salvador',
-          'SY' => 'Syrian Arab Republic',
-          'SZ' => 'Swaziland',
-          'TC' => 'Turks and Caicos Islands',
-          'TD' => 'Chad',
-          'TG' => 'Togo',
-          'TH' => 'Thailand',
-          'TJ' => 'Tajikistan',
-          'TK' => 'Tokelau (Union) Group (Western Samoa)',
-          'TL' => 'East Timor (Indonesia)',
-          'TM' => 'Turkmenistan',
-          'TN' => 'Tunisia',
-          'TO' => 'Tonga',
-          'TR' => 'Turkey',
-          'TT' => 'Trinidad and Tobago',
-          'TV' => 'Tuvalu',
-          'TW' => 'Taiwan',
-          'TZ' => 'Tanzania',
-          'UA' => 'Ukraine',
-          'UG' => 'Uganda',
-          'UY' => 'Uruguay',
-          'UZ' => 'Uzbekistan',
-          'VA' => 'Vatican City',
-          'VC' => 'Saint Vincent and the Grenadines',
-          'VE' => 'Venezuela',
-          'VG' => 'British Virgin Islands',
-          'VN' => 'Vietnam',
-          'VU' => 'Vanuatu',
-          'WF' => 'Wallis and Futuna Islands',
-          'WS' => 'Western Samoa',
-          'YE' => 'Yemen',
-          'YT' => 'Mayotte (France)',
-          'ZA' => 'South Africa',
-          'ZM' => 'Zambia',
-          'ZW' => 'Zimbabwe',
-        );
-
-        if (isset($countries[$countryId])) {
-            return $countries[$countryId];
-        }
-
-        return false;
-    }
-
-    /**
-     * @deprecated
-     */
-    protected function _methodsMapper($method, $valuesToLabels = true)
-    {
-        return $method;
-    }
-
-    /**
-     * @deprecated
-     */
-    public function getMethodLabel($value)
-    {
-        return $this->_methodsMapper($value, true);
-    }
-
-    /**
-     * @deprecated
-     */
-    public function getMethodValue($label)
-    {
-        return $this->_methodsMapper($label, false);
-    }
-
-    /**
-     * @deprecated
-     */
-    protected function setTrackingReqeust()
-    {
-        $this->setTrackingRequest();
-    }
-}
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index ca687fb7a19..1281b83884a 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -59,7 +59,7 @@ $_block = $this;
             <th><?php echo Mage::helper('catalog')->__('Label') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Sort Order') ?></th>
             <?php foreach ($_block->getImageTypes() as $typeId=>$type): ?>
-            <th><?php echo $type['label'] ?></th>
+            <th><?php echo $this->escapeHtml($type['label'], array('br')); ?></th>
             <?php endforeach; ?>
             <th><?php echo Mage::helper('catalog')->__('Exclude') ?></th>
             <th class="last"><?php echo Mage::helper('catalog')->__('Remove') ?></th>
diff --git app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
index 14f14777f8f..c053b58e07f 100644
--- app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
@@ -77,7 +77,7 @@
 
         <tr>
             <td class="label"><label for="inventory_min_sale_qty"><?php echo Mage::helper('catalog')->__('Minimum Qty Allowed in Shopping Cart') ?></label></td>
-            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo $this->getFieldValue('min_sale_qty')*1 ?>" <?php echo $_readonly;?>/>
+            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo (bool)$this->getProduct()->getId() ? (int)$this->getFieldValue('min_sale_qty') : Mage::helper('catalog/product')->getDefaultProductValue('min_sale_qty', $this->getProduct()->getTypeId()) ?>" <?php echo $_readonly ?>/>
 
             <?php $_checked = ($this->getFieldValue('use_config_min_sale_qty') || $this->IsNew()) ? 'checked="checked"' : '' ?>
             <input type="checkbox" id="inventory_use_config_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][use_config_min_sale_qty]" value="1" <?php echo $_checked ?> onclick="toggleValueElements(this, this.parentNode);" class="checkbox" <?php echo $_readonly;?> />
diff --git app/design/adminhtml/default/default/template/customer/tab/addresses.phtml app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
index 8aa82d3f57d..4e93b7902e0 100644
--- app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
@@ -46,7 +46,7 @@
             </a>
             <?php endif;?>
             <address>
-                <?php echo $_address->format('html') ?>
+                <?php echo $this->maliciousCodeFilter($_address->format('html')) ?>
             </address>
             <div class="address-type">
                 <span class="address-type-line">
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 100ef71e8e6..d423aa0013e 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -75,7 +75,7 @@ $createDateStore    = $this->getStoreCreateDate();
         </table>
         <address class="box-right">
             <strong><?php echo $this->__('Default Billing Address') ?></strong><br/>
-            <?php echo $this->getBillingAddressHtml() ?>
+            <?php echo $this->maliciousCodeFilter($this->getBillingAddressHtml()) ?>
         </address>
     </fieldset>
 </div>
diff --git app/design/adminhtml/default/default/template/notification/window.phtml app/design/adminhtml/default/default/template/notification/window.phtml
index 709403310bd..b40bf1f9680 100644
--- app/design/adminhtml/default/default/template/notification/window.phtml
+++ app/design/adminhtml/default/default/template/notification/window.phtml
@@ -68,7 +68,7 @@
     </div>
     <div class="message-popup-content">
         <div class="message">
-            <span class="message-icon message-<?php echo $this->getSeverityText();?>" style="background-image:url(<?php echo $this->getSeverityIconsUrl() ?>);"><?php echo $this->getSeverityText();?></span>
+            <span class="message-icon message-<?php echo $this->getSeverityText(); ?>" style="background-image:url(<?php echo $this->escapeUrl($this->getSeverityIconsUrl()); ?>);"><?php echo $this->getSeverityText(); ?></span>
             <p class="message-text"><?php echo $this->getNoticeMessageText(); ?></p>
         </div>
         <p class="read-more"><a href="<?php echo $this->getNoticeMessageUrl(); ?>" onclick="this.target='_blank';"><?php echo $this->getReadDetailsText(); ?></a></p>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index 04587356c0a..88c6364dea9 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -39,9 +39,9 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
         endif; ?>
         <div class="entry-edit-head">
         <?php if ($this->getNoUseOrderLink()): ?>
-            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?> (<?php echo $_email ?>)</h4>
+            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?> (<?php echo $_email ?>)</h4>
         <?php else: ?>
-            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?></a>
+            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?></a>
             <strong>(<?php echo $_email ?>)</strong>
         <?php endif; ?>
         </div>
@@ -69,7 +69,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the New Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationChildId()) ?>">
-                    <?php echo $_order->getRelationChildRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationChildRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -77,7 +77,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the Previous Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationParentId()) ?>">
-                    <?php echo $_order->getRelationParentRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationParentRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -152,7 +152,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <h4 class="icon-head head-billing-address"><?php echo Mage::helper('sales')->__('Billing Address') ?></h4>
         </div>
         <fieldset>
-            <address><?php echo $_order->getBillingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getBillingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
@@ -164,7 +164,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <h4 class="icon-head head-shipping-address"><?php echo Mage::helper('sales')->__('Shipping Address') ?></h4>
         </div>
         <fieldset>
-            <address><?php echo $_order->getShippingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getShippingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
diff --git app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
index f554a00095a..81f165599c4 100644
--- app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
+++ app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
@@ -38,7 +38,7 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <tr class="headings">
                 <th class="a-right">&nbsp;</th>
                 <?php $_i = 0; foreach( $this->getAllowedCurrencies() as $_currencyCode ): ?>
-                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $_currencyCode ?><strong></th>
+                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?><strong></th>
                 <?php endforeach; ?>
             </tr>
         </thead>
@@ -47,16 +47,16 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <?php if( isset($_rates[$_currencyCode]) && is_array($_rates[$_currencyCode])): ?>
                 <?php foreach( $_rates[$_currencyCode] as $_rate => $_value ): ?>
                     <?php if( ++$_j == 1 ): ?>
-                        <td class="a-right"><strong><?php echo $_currencyCode ?></strong></td>
+                        <td class="a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?></strong></td>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates) && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
                         </th>
                     <?php else: ?>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates)  && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
index 040c286c4e5..015d9081d4d 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
@@ -36,9 +36,15 @@ if (!$_cards) {
         <th colspan="<?php echo $this->getColspan(); ?>" style="<?php echo $this->getTotal()->getStyle() ?>" class="a-right">
             <?php if ($this->getRenderingArea() == $this->getTotal()->getArea()): ?><strong><?php endif; ?>
                 <?php $_title = $this->__('Remove'); ?>
-                <?php $_url = Mage::getUrl('enterprise_giftcardaccount/cart/remove', array('code'=>$_c['c'])); ?>
-                <a href="<?php echo $_url; ?>" title="<?php echo $_title; ?>" class="btn-remove"><img src="<?php echo $this->getSkinUrl('images/btn_remove.gif') ?>" alt="<?php echo $this->__('Remove')?>" /></a>
-
+                <a title="<?php echo Mage::helper('core')->quoteEscape($_title); ?>"
+                   href="#"
+                   class="btn-remove"
+                   onclick="customFormSubmit(
+                           '<?php echo (Mage::getUrl('enterprise_giftcardaccount/cart/remove')); ?>',
+                           '<?php echo ($this->escapeHtml(json_encode(array('code' => $_c['c'])))); ?>',
+                           'post')">
+                    <img src="<?php echo $this->getSkinUrl('images/btn_remove.gif') ?>" alt="<?php echo $this->__('Remove')?>" />
+                </a>
                 <?php echo $this->__('Gift Card (%s)', $_c['c']); ?>
             <?php if ($this->getRenderingArea() == $this->getTotal()->getArea()): ?></strong><?php endif; ?>
         </th>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 66dc2e66415..4ef4d5ce83c 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -39,7 +39,7 @@
 "6 Hours","6 Hours"
 "<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>","<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>"
 "A new password was sent to your email address. Please check your email and click Back to Login.","A new password was sent to your email address. Please check your email and click Back to Login."
-"A user with the same user name or email aleady exists.","A user with the same user name or email aleady exists."
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
 "API Key","API Key"
 "API Key Confirmation","API Key Confirmation"
 "Abandoned Carts","Abandoned Carts"
@@ -224,6 +224,7 @@
 "Credit memo #%s created","Credit memo #%s created"
 "Credit memo\'s total must be positive.","Credit memo\'s total must be positive."
 "Currency","Currency"
+"Currency doesn\'t exist.","Currency doesn\'t exist."
 "Currency Information","Currency Information"
 "Currency Setup Section","Currency Setup Section"
 "Current Configuration Scope:","Current Configuration Scope:"
@@ -786,6 +787,7 @@
 "Self-assigned roles cannot be deleted.","Self-assigned roles cannot be deleted."
 "Sender","Sender"
 "Separate Email","Separate Email"
+"Serialized data is incorrect","Serialized data is incorrect"
 "Shipment #%s comment added","Shipment #%s comment added"
 "Shipment #%s created","Shipment #%s created"
 "Shipment Comments","Shipment Comments"
@@ -890,6 +892,7 @@
 "The email address is empty.","The email address is empty."
 "The email template has been deleted.","The email template has been deleted."
 "The email template has been saved.","The email template has been saved."
+"Invalid template data.","Invalid template data."
 "The flat catalog category has been rebuilt.","The flat catalog category has been rebuilt."
 "The group node name must be specified with field node name.","The group node name must be specified with field node name."
 "The image cache was cleaned.","The image cache was cleaned."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index e2cb63f8d6f..0d472a154de 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -40,6 +40,7 @@
 "Can't retrieve request object","Can't retrieve request object"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed template variable method.","Disallowed template variable method."
 "Cannot retrieve entity config: %s","Cannot retrieve entity config: %s"
 "Card type does not match credit card number.","Card type does not match credit card number."
 "Code","Code"
diff --git app/locale/en_US/Mage_Sales.csv app/locale/en_US/Mage_Sales.csv
index 11535872b0a..fd83ddfd4a4 100644
--- app/locale/en_US/Mage_Sales.csv
+++ app/locale/en_US/Mage_Sales.csv
@@ -241,6 +241,7 @@
 "Invalid draw line data. Please define ""lines"" array.","Invalid draw line data. Please define ""lines"" array."
 "Invalid entity model","Invalid entity model"
 "Invalid item option format.","Invalid item option format."
+"Invalid order data.","Invalid order data."
 "Invalid qty to invoice item ""%s""","Invalid qty to invoice item ""%s"""
 "Invalid qty to refund item ""%s""","Invalid qty to refund item ""%s"""
 "Invalid qty to ship for item ""%s""","Invalid qty to ship for item ""%s"""
diff --git app/locale/en_US/Mage_Sitemap.csv app/locale/en_US/Mage_Sitemap.csv
index 8ae5a947caf..df201861844 100644
--- app/locale/en_US/Mage_Sitemap.csv
+++ app/locale/en_US/Mage_Sitemap.csv
@@ -44,3 +44,4 @@
 "Valid values range: from 0.0 to 1.0.","Valid values range: from 0.0 to 1.0."
 "Weekly","Weekly"
 "Yearly","Yearly"
+"Please enter a sitemap name with at most %s characters.","Please enter a sitemap name with at most %s characters."
diff --git js/mage/adminhtml/wysiwyg/tiny_mce/setup.js js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
index 6cf6766e64e..db89e58103f 100644
--- js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
+++ js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
@@ -108,6 +108,7 @@ tinyMceWysiwygSetup.prototype =
             theme_advanced_resizing : true,
             convert_urls : false,
             relative_urls : false,
+            media_disable_flash : this.config.media_disable_flash,
             content_css: this.config.content_css,
             custom_popup_css: this.config.popup_css,
             magentowidget_url: this.config.widget_window_url,
diff --git js/varien/js.js js/varien/js.js
index e9013910875..67da0db3761 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -577,3 +577,40 @@ function fireEvent(element, event){
         return !element.dispatchEvent(evt);
     }
 }
+
+/**
+ * Create form element. Set parameters into it and send
+ *
+ * @param url
+ * @param parametersArray
+ * @param method
+ */
+Varien.formCreator = Class.create();
+Varien.formCreator.prototype = {
+    initialize : function(url, parametersArray, method) {
+        this.url = url;
+        this.parametersArray = JSON.parse(parametersArray);
+        this.method = method;
+        this.form = '';
+
+        this.createForm();
+        this.setFormData();
+    },
+    createForm : function() {
+        this.form = new Element('form', { 'method': this.method, action: this.url });
+    },
+    setFormData : function () {
+        for (var key in this.parametersArray) {
+            Element.insert(
+                this.form,
+                new Element('input', { name: key, value: this.parametersArray[key], type: 'hidden' })
+            );
+        }
+    }
+};
+
+function customFormSubmit(url, parametersArray, method) {
+    var createdForm = new Varien.formCreator(url, parametersArray, method);
+    Element.insert($$('body')[0], createdForm.form);
+    createdForm.form.submit();
+}
