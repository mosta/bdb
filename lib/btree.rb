require 'bdb'

module BDB
  
  class BTree

    def initialize(file_name = nil, table_name = nil,  marshal= false, env=nil)
      @db = env ? env.db : Bdb::Db.new
      @db.flags = @db.flags
      @file_name = file_name
      @table_name = table_name   
      @db.open(nil, file_name, table_name, Bdb::Db::BTREE, Bdb::DB_CREATE, 0)
      @marshal = marshal 
      @env = env
      #@dbc = @db.cursor(nil,0)
    end
    
    def put(key,data,transaction=nil,flags=0)
      @db.put(transaction, format_data(key), @marshal ? Marshal.dump(data) : format_data(data) ,flags)
    end

   def push(data)
      put(Time.now.to_f,data)
   end
        
    def get(key,data=nil,transaction=nil,flags=0)
      key,val = @db.get(transaction, format_data(key), data, flags)
      [key, @marshal ? Marshal.load(val) : val ] if val
    end
    
    def pget(key,data=nil,transaction=nil,flags=0)
      key,val = @db.pget(transaction, format_data(key), data, flags)
      [key, @marshal ? Marshal.load(val) : val ] if val
    end    

    def pop
      @dbc = @db.cursor(nil,Bdb::DB_WRITECURSOR)
      key, val = @dbc.get(nil,nil,Bdb::DB_FIRST) if @dbc
      @dbc.del  if key
      @dbc.close()
      res = key ? [key,@marshal ? Marshal.load(val) : val] : []
    end

    def first
      @dbc = @db.cursor(nil,0)
      key, val = @dbc.get(nil,nil,Bdb::DB_FIRST)
      @dbc.close()
      res = [key,@marshal ? Marshal.load(val) : val]
    end


    def delete_one_entry(key,transaction=nil,flags=0)
     dbc = @db.cursor(nil,0)
     key, val = dbc.get(format_data(search_key),nil,Bdb::DB_SET_RANGE)
     dbc.close
     [key, val]
    end
    
    def delete(key,transaction=nil,flags=0)
      @db.del(transaction, format_data(key), flags)
    end
    

   def delete_smaller(search_key)
      dbc = @db.cursor(nil,0)
      key, val = dbc.get(nil,nil,Bdb::DB_FIRST)
      dbc.del if key && key  < format_data(search_key)
      while key
        key, val = dbc.get(nil,nil,Bdb::DB_NEXT)
        dbc.del if key && key  < format_data(search_key)
      end
      dbc.close
   end

    def db
      @db
    end

    def get_bigger(search_key)
      result = []
      dbc = @db.cursor(nil,0)
      key, val = dbc.get(format_data(search_key),nil,Bdb::DB_SET_RANGE)
      if(val && key > format_data(search_key))
       if @marshal
        result <<  Marshal.load(val)
       else
        result <<  val 
       end
      end
      while key
        key, val = dbc.get(nil,nil,Bdb::DB_NEXT)
        if val
         if @marshal 
          result << Marshal.load(val)
         else
          result << val
         end 
        end
      end
      dbc.close
      result
    end
 
 def delete_less_than(search_key)
      dbc = @db.cursor(nil,Bdb::DB_WRITECURSOR)
      p dbc.inspect
      key, val = dbc.get(format_data(search_key),nil,Bdb::DB_FIRST)
      p key.to_f
      if(val && key <= format_data(search_key))
         dbc.del
      end
      while key
        break if key > format_data(search_key)
        key, val = dbc.get(nil,nil,Bdb::DB_NEXT)
        dbc.del
      end
      dbc.close
   end

    def count
      @db.stat(nil,0).inspect
    end
 
    def close
      @db.close(0)
    end
  
  protected
    def format_data(key)
        if key.is_a? ::Fixnum
          return sprintf("%010d", key)
        elsif key.is_a? ::Float
          return sprintf("%020f", key) 
        end
        key
      end

  end
  
end

if __FILE__ == $0
  btree = BDB::BTree.new('test.tdb')
  #puts "adding 1000 items"
  #1000.times do |i|
  #  btree.put(i, i.to_s)
  #end
  #puts "searching for items with keys bigger than 375"
  #result = btree.get_bigger(375)
  #p result 
  #p result.length 
  #require 'benchmark'
  #puts Benchmark.realtime { 120000.times { |i| btree.put(i, i.to_s) } }
  #btree.close
  #File.unlink('test.tdb')


end
