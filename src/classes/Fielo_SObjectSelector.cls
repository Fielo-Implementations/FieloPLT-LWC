public abstract class Fielo_SObjectSelector{
    
    private Boolean m_includeFieldSetFields;
    private Boolean m_enforceFLS;
    private Boolean m_enforceCRUD;

    private Integer lim;
    private Integer offset;
    private String m_orderBy;
    
    private Set<String> fields;

    abstract Schema.SObjectType getSObjectType();
    abstract List<Schema.SObjectField> getSObjectFieldList();

    //SETTERS
    public void setFieldList(Set<String> fields){
        this.fields = deleteDuplicateFields(fields);
    }

    public void setLimit(Integer lim){
        this.lim = lim;
    }

    public void setOffset(Integer offset){
        this.offset = offset;
    }

    public void setOrderBy(String orderBy){
        this.m_orderBy = orderBy;
    }

    //GETTERS
    public String getSObjectName(){
        return String.valueOf(getSObjectType());
    }
    
    public String getFieldListString(){
        if(!fields.isEmpty()){
            return String.join(new List<String>(fields),',');
        } else{
            if(getSObjectFieldList().size() <= 10){
                return String.valueof(getSObjectFieldList()).remove('(').remove(')');
            }else{
                List<String> customList = new List<String>();
                for(Schema.SObjectField objField : getSObjectFieldList()){
                    customList.add(String.valueOf(objField));
                }
                return String.join(customList,',');
            }
        }
    }

    public virtual String getOrderBy(){
        if(m_orderBy == null){
            return '';
        }
        return ' ORDER BY ' + m_orderBy;
    }

    public String getOffsetCondition(){
        if(this.offset != null){
            return ' OFFSET ' + String.valueOf(offset);
        }
        return '';        
    }

    public String getLimitCondition(){
        if(this.lim != null){
            return ' LIMIT ' + String.valueOf(lim);
        }
        return '';
    }

    //CONSTRUCTORS
    public Fielo_SObjectSelector(Set<String> fields){
        this(false);
        setFieldList(fields);
    }

    public Fielo_SObjectSelector(){        
        this(false);
    }

    public Fielo_SObjectSelector(Boolean includeFieldSetFields){
        this(includeFieldSetFields, true, false);
    }

    public Fielo_SObjectSelector(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS){
        m_includeFieldSetFields = includeFieldSetFields;
        m_enforceCRUD = enforceCRUD;
        m_enforceFLS = enforceFLS;
        this.fields = new Set<String>();
    }

    public String getRelatedParentFieldListString(String relation){
        List<String> setParentFields = new List<String>();
        for(String field: this.fields){
            setParentFields.add(relation + '.' + field);
        }
        return string.join(setParentFields,', ');
    }

    public String getRelatedParentFieldListStringToLabel(String relation){
        List<String> setParentFields = new List<String>();
        for(String field: this.fields){

            //chequeo si el campo viene con el toLabel()
            if(field.contains('tolabel(')){
                //remuevo el toLabel( y lo pongo adelante
                field = field.remove('tolabel(');
                setParentFields.add('tolabel(' + relation + '.' + field);
            }else{
                setParentFields.add(relation + '.' + field);
            }
        }
        return string.join(setParentFields,', ');
    }

    public List<SObject> selectSObjectsById(Set<Id> idSet){                
        //assertIsAccessible();
        return Database.query(buildQuerySObjectById());
    }

    public Database.QueryLocator queryLocatorById(Set<Id> idSet){
        return Database.getQueryLocator(buildQuerySObjectById());
    }

    public void assertIsAccessible(){
        /*if(!getSObjectType().getDescribe().isAccessible())
           throw new SObjectDomain.DomainException(
                'Permission to access an ' + getSObjectType().getDescribe().getName() + ' denied.');*/
    }

    /**
     * Public acccess for the getSObjectType during Mock registration
     *   (adding public to the existing method broken base class API backwards compatability)
     **/
    public SObjectType sObjectType(){
        return getSObjectType();
    }

    /**
     * Constructs the default SOQL query for this selector, see selectSObjectsById and queryLocatorById
     **/
    private String buildQuerySObjectById(){        
        return String.format(
            'SELECT {0} FROM {1} WHERE id in :idSet {2} {3} {4}',
            new List<String>{getFieldListString(),getSObjectName(),getOrderBy(),getLimitCondition(),getOffsetCondition()}
        );
    }

    private Set<String> deleteDuplicateFields(Set<String> fields){
        Set<String> filtersFields = new Set<String>();
        if (!fields.isEmpty()) {
            for(String f: fields){
                filtersFields.add(f.toLowerCase());
            }
        }
        return filtersFields;
    }

}