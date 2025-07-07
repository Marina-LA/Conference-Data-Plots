<br/>
<div align="center">
    <img src="logo.png" alt="Logo" width="500">
</div>

> :soon: We are working to create a small webpage to display the results extracted from the conference data obtained with the crawler.

# :chart_with_upwards_trend: Data

**This directory contains data from 10 conferences extracted with the crawler we have created.**

> :warning: It is important to note that the data shown here has been modified afterward, as the crawler cannot obtain all the information from some conferences. To have the most complete data possible, additional information has been added after the crawling process.

These data may also contain fields that are not extracted by the crawler. This is because the crawler has been modified over time, and some fields that were extracted but not used have been removed in the current version of the crawler (with some minor modifications to the crawler, this can be changed).

# :file_folder: Data Directories

> :heavy_exclamation_mark: It should be noted that there is a large amount of data, and due to its nature and difficult extraction, it may contain errors and empty fields.

- **``CrawlerData``**: This includes all the files obtained with the crawler (some may have been modified afterward). Inside, we find three different directories, one for each crawler's data: ``BaseCrawler``, ``ExtendedCrawler``, and ``CitationsCrawler``.

- **``ProcessedData``**: These are the basic data of the papers, meaning the data we consider most essential for analysis. They do not include citation data. This data was obtained by processing the ``ExtendedCrawler`` data from each of the conferences.

    - ***``unifiedPaperData.csv``*** - Additional CSV that consolidates the main data from the papers. This data includes the conference where the paper was published, the year of publication, the paper title, and the continent assigned as predominant.

    - ***``unifiedCitationData.csv``*** - Additional CSV that consolidates the main continent data from the cited papers. This data includes the conference to which the papers that have cited other papers belong, the predominant continent of the papers that have been cited in that conference, and the number of papers belonging to each of the different continents.

- **``CommitteeData``**: They contain all data on the conference Program Committees. These data were extracted manually (with some help from a crawler). As a result, they may contain some errors.

- **``Databases``**: This folder includes the database files. On the one hand, it has the files that make up the relational database (one for each conference). On the other hand, it contains the ``.dump`` files for the GraphDB (one for each conference). The GraphDB was created using [Neo4j](https://neo4j.com)
