package net.systemeD.potlatch2.mapfeatures {

    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.net.*;
    import flash.utils.ByteArray;
    
    import net.systemeD.halcyon.connection.Entity;
    import net.systemeD.potlatch2.utils.CachedDataLoader;

	public class Feature extends EventDispatcher {
        private var mapFeatures:MapFeatures;
        private var _xml:XML;
        private static var variablesPattern:RegExp = /[$][{]([^}]+)[}]/g;
        private var _tags:Array;
        private var _editors:Array;

        public function Feature(mapFeatures:MapFeatures, _xml:XML) {
            this.mapFeatures = mapFeatures;
            this._xml = _xml;
            parseTags();
            parseEditors();
        }
        
        private function parseTags():void {
            _tags = new Array();
            
            for each(var tag:XML in definition.tag) {
                var tagObj:Object = new Object();
                tagObj["k"] = tag.@k;
                tagObj["v"] = tag.@v;
                _tags.push(tagObj);
            }
        }
        
        private function parseEditors():void {
            _editors = new Array();
            
            addEditors(definition);
            
            _editors.sortOn(["sortOrder", "name"], [Array.DESCENDING | Array.NUMERIC, Array.CASEINSENSITIVE]);
        }
        
        private function addEditors(xml:XML):void {
            var inputXML:XML;
            
            for each(var inputSetRef:XML in xml.inputSet) {
                var setName:String = String(inputSetRef.@ref);
                for each (inputXML in mapFeatures.definition.inputSet.(@id==setName)) {
                    addEditors(inputXML);
                }
            }
            
            for each(inputXML in xml.input) {
                addEditor(inputXML);
            }
        }
        
        private function addEditor(inputXML:XML):void {
            var inputType:String = inputXML.@type;
            var presenceStr:String = inputXML.@presence;
            var sortOrderStr:String = inputXML.@priority;
            var editor:EditorFactory = EditorFactory.createFactory(inputType, inputXML);
            if ( editor != null ) {
                editor.presence = Presence.getPresence(presenceStr);
                editor.sortOrder = EditorFactory.getPriority(sortOrderStr);
                _editors.push(editor);
            }
        }
        
        public function get editors():Array {
            return _editors;
        }
        
        public function get definition():XML {
            return _xml;
        }
    
        [Bindable(event="nameChanged")]
        public function get name():String {
            return _xml.@name;
        }
    
        [Bindable(event="imageChanged")]
        public function get image():ByteArray {
            var icon:XMLList = _xml.icon;
            var imageURL:String = null;

            if ( icon.length() > 0 && icon[0].hasOwnProperty("@image") )
                imageURL = icon[0].@image;
            
            if ( imageURL != null ) {
                return CachedDataLoader.loadData(imageURL, imageLoaded);
            }
            return null;
        }
        
        private function imageLoaded(url:String, data:ByteArray):void {
            dispatchEvent(new Event("imageChanged"));
        }
        
        public function htmlDetails(entity:Entity):String {
            var icon:XMLList = _xml.icon;
            return makeHTMLIcon(icon, entity);
        }   

        public static function makeHTMLIcon(icon:XMLList, entity:Entity):String {
            if ( icon == null )
                return "";
            
            var txt:String = icon.children().toXMLString();
            var replaceTag:Function = function():String {
                var value:String = entity.getTag(arguments[1]);
                return value == null ? "" : htmlEscape(value);
            };
            txt = txt.replace(variablesPattern, replaceTag);
            return txt;
        }
        
        public static function htmlEscape(str:String):String {
            var newStr:String = str.replace(/&/g, "&amp;");
            newStr = newStr.replace(/</g, "&lt;");
            newStr = newStr.replace(/>/g, "&gt;");
            newStr = newStr.replace(/"/g, "&quot;");	// "
            newStr = newStr.replace(/'/g, "&apos;");	// '
            return newStr;
        }
      

        public function isInCategory(category:String):Boolean {
            var cats:XMLList = _xml.category;
            if ( cats.length() == 0 )
                return false;
                
            for each( var cat:XML in cats )
                if ( cat.text()[0] == category )
                    return true;
            return false;
        }
        
        public function get tags():Array {
            return _tags;
        }
        
        public function findFirstCategory():Category {
            for each( var cat:Category in mapFeatures.categories ) {
                if ( isInCategory(cat.id) )
                    return cat;
            }
            return null;
        }
        
        public function isType(type:String):Boolean {
            if (type=='area') {
			    return (_xml.elements(type).length() > 0) || (_xml.elements('line').length() > 0);
            } else {
			    return _xml.elements(type).length() > 0;
			}
        }
        
        public function hasHelpURL():Boolean {
            return _xml.help.length() > 0;
        }
        
        public function get helpURL():String {
            return _xml.help;
        }
    }
}

