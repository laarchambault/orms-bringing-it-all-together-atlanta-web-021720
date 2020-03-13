require 'pry'
class Dog
    attr_accessor :name, :breed, :id

    def initialize(name:, breed:, id:nil)
        @name = name
        @breed = breed
        @id = id
    end

    def self.create_table
        sql = <<-SQL
            CREATE TABLE IF NOT EXISTS dogs (
                id INTEGER PRIMARY KEY,
                name TEXT,
                breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
            DROP TABLE IF EXISTS dogs
        SQL
        DB[:conn].execute(sql)
    end

    def update(name, breed)
        sql = <<-SQL
        UPDATE dogs
        SET name = ?, breed = ?
        WHERE id = ?
        SQL
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end

    def save
        if self.id
            self.update
        else
        sql = <<-SQL
            INSERT INTO dogs (name, breed)
            VALUES (?, ?)
        SQL

        DB[:conn].execute(sql, self.name, self.breed)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end
        self
    end

    def self.create(hash)
        dog = self.new(name: hash[:name], breed: hash[:breed])
        hash.each do |key, value|
            dog.send(("#{key}="), value)
        end
        dog.save
        dog
    end

    def self.new_from_db(row)
        self.new(name: row[1], breed: row[2], id: row[0])
    end

    def self.find_by_id(given_id)
        sql = <<-SQL
            SELECT * FROM dogs
            WHERE id = ?
        SQL

        dog_row = DB[:conn].execute(sql, given_id)
        dog = self.new_from_db(dog_row[0])
        dog
    end


    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL
        SELECT * FROM dogs
        WHERE name = ? AND breed = ?
        LIMIT 1
        SQL

        dog_arr = (DB[:conn].execute(sql, name, breed))[0]
        #binding.pry
        if !dog_arr.empty?
            new_dog = self.find_by_id(dog_arr[0])
        else
            new_dog = self.new(name: dog_arr[1], breed: dog_arr[2])
            new_dog.save
        end
        new_dog
    end

end