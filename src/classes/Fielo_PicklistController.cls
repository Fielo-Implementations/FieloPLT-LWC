
global with sharing class Fielo_PicklistController {

	global class Entry {
		public String Id{get;set;}
		public String Label{get;set;}
		public String MetaLabel{get;set;}

		global Entry ( String Id, String Label ) {
			  this.Id = Id;
			  this.Label = Label;
        }
    }
}