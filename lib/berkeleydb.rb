require 'hash_table'
require 'btree'
require 'queue'
require 'bdb'

module BDB
  class Env
    def initialize(path,flags=0,options={})
      @env = Bdb::Env.new(0) 
      @env_flags =   Bdb::DB_CREATE |    # Create the environment if it does not already exist.
               Bdb::DB_INIT_MPOOL|   # Initialize the in-memory cache.
               Bdb::DB_INIT_CDB | flags # Initialize the in-memory cache.
      @env.open(path, @env_flags, 0);
    end
    
    def hash(file_name=nil,table_name=nil,marshal=false)
      HashTable.new(file_name,table_name,marshal,@env)
    end

    def btree(file_name=nil,table_name=nil,marshal=false)
      BTree.new(file_name,table_name,marshal,@env)
    end
    
    #def add_index(primary_database)
    
    #end

    def queue(record_length=0,file_name=nil,table_name=nil,marshal=false)
      BDB::Queue.new(record_length,file_name,table_name,marshal,@env)
    end
    
    def close
      @env.close
    end
    
  end
end


if __FILE__ == $0

  e = BDB::Env.new("berkeleydb/testdb")
  h = e.hash("test_index" , "primary_index")
  b = e.btree("test_index" , "secondary_index")


  #b.put("1" , "One")
  #b.put("2" , "Two")
  #b.put("5" , "Five")
  #puts   b.get_bigger("2")
  dbh = h.instance_variable_get :@db
  
  dbb = b.instance_variable_get :@db  

  dbh.associate(nil,dbb,0,proc {|s,key,data| data } )

  h.put("1" , "One")
  #dbc = dbb.cursor(nil,0)
  #key, val = dbc.get(nil,nil,Bdb::DB_FIRST)
  #p key,val
  p dbb.pget(nil,"One",nil,0)[0]


  h.put("1" , "Un")

  p dbb.pget(nil,"Un",nil,0)

  b.close
  h.close
  e.close
end
