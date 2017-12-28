#
# Copyright (c) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'
require 'set'

#
# This class remembers the pieces of that that need to be remembered in order to avoid processing
# twice notices received from Kubernetes watches.
#
# Note that the implementation currently stores the data in a local JSON file. That isn't correct
# for a real production environment. This should be changed to write to the database, or to some
# other kind of persistent storage that can be accessed concurrently by multiple workers.
#
class ManageIQ::Providers::Kubevirt::RefreshMemory
  #
  # Creates a new object to hold the refresh data for the manager with the given identifier.
  #
  # @param id [String] The unique identifier of the manager.
  #
  def initialize(id)
    # Save the identifier of the manager:
    @id = id

    # Initialize the hash that contains the last resource version for each kind of list. The keys of
    # this hash will be strings identifying the kind of object, for example `live_vms`. The values will
    # be the last `resourceVersion` that was obtained when listing that kind of object.
    @lists = {}

    # Initialize the set that contains the keys of the notices that have already been processed.
    @notices = Set.new

    # Load the JSON file:
    load
  end

  #
  # Returns `true` if there is no data.
  #
  # @return [Boolean] A boolean value indicating if there is no data.
  #
  def empty?
    @lists.empty? && @notices.empty?
  end

  #
  # Sets the last resource version that has been obtained when listing the given kind of object.
  #
  # @param kind [String] The kind of object, for example `live_vms`.
  # @param version [String] The resource version.
  #
  def add_list_version(kind, version)
    kind = kind.to_s
    @lists[kind] = version
    save
  end

  #
  # Returns the last resource version that was obtained when listing the given kind of object.
  #
  # @param kind [String] The kind of object, for example `live_vms`.
  # @return [String] The resource version.
  #
  def get_list_version(kind)
    kind = kind.to_s
    @lists[kind]
  end

  #
  # Adds a notice that has been already processed.
  #
  # @param notice [Object] The notice object.
  #
  def add_notice(notice)
    key = notice_key(notice)
    unless @notices.include?(key)
      @notices.add(key)
      save
    end
  end

  #
  # Checks if this data contains the given notice.
  #
  # @param notice [Object] The notice to check.
  # @return [boolean] A boolean value indicating if this data contains the given notice.
  #
  def contains_notice?(notice)
    key = notice_key(notice)
    @notices.include?(key)
  end

  private

  #
  # Names for JSON attributes:
  #
  LISTS = 'lists'.freeze
  NOTICES = 'notices'.freeze

  #
  # Calculates the key that will be used to store a notice.
  #
  def notice_key(notice)
    object = notice.object
    metadata = object.metadata
    "#{object.kind}:#{metadata.uid}:#{notice.type}:#{metadata.resourceVersion}"
  end

  #
  # Loads this data from persistent storage.
  #
  def load
    # Load the JSON document:
    return unless File.exists?(file)
    text = File.read(file)
    json = JSON.parse(text)

    # Copy the relevant JSON data to the instance variables:
    @lists = json[LISTS]
    @notices.clear
    @notices.merge(json[NOTICES])
  end

  #
  # Saves this data to persistent storage.
  #
  def save
    # Populate the JSON object from the instance variables:
    json = {
      LISTS => @lists,
      NOTICES => @notices.to_a.sort!
    }

    # Convert the JSON object to text and save it to the file:
    text = JSON.pretty_generate(json)
    File.write(file, text)
  end

  #
  # Calculates the name of the file where the data is saved.
  #
  # @return [String] The name of the file.
  #
  def file
    @file ||= "#{@id}-refresh-memory.json"
  end
end
