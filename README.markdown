Welcome to the Filtered-Models wiki, here you'll see the basic idea behind this small Rails plugin.

# Introduction

Filtered Models is my first attemp at some middle-level ruby meta programming. With it I intent to provide the Rails framework with a couple of methods to improve the ActiveRecord development, which in turn go very much along with Ruby's DRY methodology.

The filters provided by this plugin are:

* before_filter
* after_filter

The idea behind this filters is for them to work exactly like they do on rails' controllers. As you'll see in the use examples, they provide the same functionality.

# Implemented features

Both filters have support for the following forms:

* `before_filter :method`
* `before_filter :method, :only => [:method1, :method2]`
* `before_filter :method, :except => [:method1, :method2]`
* `before_filter :method, :only => [:method1, :method2] do |m|
        #code here (m is the model)
end`

* `before_filter :only => [:method1, :method2] do |m|
        #code here (m is the model)
end`

When :only or :except are used, if only one method needs to be filtered, then there is no need to use an array, i.e: before_filter :method, :only => :method_filtered

## Filters configuration 

By default, filters that apply to all methods will *ignore* automatically generated attribute accessors (those generated with _attr_reader_, _attr_writer_ or _attr_accessor). You can disable this and allow these type of filters to execute when an accessor is called.
To do this, the following methods are provided:

* configure_before_filters / configure_after_filters: They both take an array of arguments, with different configuration options.

The following options are currently available to configure the filters

* :include_accessors : Automatically generated accessors will be filtered

# Installation

**Rails 3.X:**
In order to install this plugin, it should be enough to just copy the entire folder under vendor/plugins.

**Rails 2.3.X:**
In order to make the plugin work on this version of rails, the follwing file needs to be edited: _config/environment.rb_

Uncomment or add the following line inside the initializer method call: ``` config.plugins = [:filtered_models]```

# Use examples

```ruby
class Test < ActiveRecord::base
    before_filter :filter_method, :only => [:filtered_method]
    after_filter :last_method, :only => [:filtered_method]
    after_filter :always


    def always
        #this method will be called after every single method defined here, except itself
    end
    def filter_method
        # your filter code here
    end
    def filtered_method
        #  your code here
    end
    def last_method
        #this code will execute always after a method is invoked
    end
end
```



# TODO's

Since this is a work in progress, there are still a couple of things left to do, and probably more that I still don't know:

* Do some serious testing.
* Don't allow infinite loops

# Contact the author

Please, feel free to contact me if you have any problems with the code, or if you're even using it, I'd love to hear from you at deleteman@gmail.com

