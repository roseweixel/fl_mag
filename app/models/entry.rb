class Entry < ActiveRecord::Base
  belongs_to :feed
  belongs_to :blogger
  has_many :entries_tags
  has_many :tags, through: :entries_tags

  before_save :slugify!

  def slugify!
    self.title != nil ? self.slug = self.title.downcase.gsub(/[\W,\s]/,'-') : self.slug = self.id
  end

  def self.most_recent
    order("published DESC").limit(1).first
  end
  
  def author_name
    self.feed.blogger.name
  end

  def author_slug
    self.feed.blogger.slug
  end

  def twitter_handle
    self.feed.blogger.twitter_handle
  end

  def tags_added
    Tag.joins(:entries_tags).where(:entries_tags => {:visible => true, :entry_id => self.id})
  end

  def safe_html(html)
    Sanitize.clean(html, {:remove_contents => true})
  end

  def publish
    self.update(:added? => true, :mag_published => Time.now)
  end

  def summarize
    if self.content
      if self.content.include?("<p>")
        first = self.content.split("<p>")[1]
        second = self.content.split("<p>")[2]
        first = safe_html(first)
        second = safe_html(second)
        first = first + "</p>" if first && !first.end_with?("</p>")
        second = second + "</p>" if second && !second.end_with?("</p>")
        "<p>" + first + "<p>" + second if first && second
      else
        "<p>" + self.content + "</p>"
      end
    end
  end

  # skip.match(/[^a-zA-Z]/).nil?

  def get_tags
    extractor = Phrasie::Extractor.new
    rough_tags = extractor.phrases(self.content, strength: 3, occur: 2)
    rough_tags.each do |tag|
      tag = Tag.where(:word => tag[0].downcase).first_or_create
      EntriesTag.create(:entry_id => self.id, :tag_id => tag.id) if tag.ignore != nil && tag.ignore != true
    end
    self.get_title_tags if self.title != nil
  end

  def get_title_tags
    rough_tags = self.title.split(" ")
    rough_tags.each do |tag|
      tag = Tag.where(:word => tag.downcase).first_or_create
      self.entries_tags.create(:tag_id => tag.id) if tag.ignore != nil && tag.ignore != true
    end
  end

  def make_all_tags_visible
    self.entries_tags.each do |entry_tag|
      entry_tag.update(visible: true)
    end
  end

  def self.featured_by_date_published
    self.where(:added? => true).order('mag_published DESC')
  end

  def self.featured_entries
    self.where(:added? => true)
  end

  def self.collect_by_tag(tag_id)
    self.joins(:entries_tags).where(:entries_tags => {:tag_id => tag_id, :visible => true } ).order("mag_published DESC")
  end

end