"""
This program takes geospatial data and several CSV file that
includes the university ranking dataset(year, rank, scores_overall,
etc.) from 2016 to 2023.
Applies Pandas, matplotlib, yellowbrick, time, re, plotly, geopandas,
warnings and scikit-learn to process, visualize, and make predictions
using machine learning model about the university ranking data.
"""


# import libraries
import pandas as pd
import geopandas as gpd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from yellowbrick.target import FeatureCorrelation
from sklearn.linear_model import Ridge
from yellowbrick.regressor import ResidualsPlot
from yellowbrick.features import Rank2D
from sklearn.neural_network import MLPClassifier
from scipy.stats import pearsonr
import time
import re
import plotly.express as px
from sklearn.linear_model import LinearRegression
import warnings
warnings.filterwarnings('ignore')


# GLOABL Variables
RANKINGS_2016 = "2016_rankings.csv"
RANKINGS_2017 = "2017_rankings.csv"
RANKINGS_2018 = "2018_rankings.csv"
RANKINGS_2019 = "2019_rankings.csv"
RANKINGS_2020 = "2020_rankings.csv"
RANKINGS_2021 = "2021_rankings.csv"
RANKINGS_2022 = "2022_rankings.csv"
RANKINGS_2023 = "2023_rankings.csv"
GDP_2016_2020 = "gdp_2016_2020.csv"


def top50_scores(data: pd.DataFrame, year: int):
    """
    Take a dataset(pd.DataFrame) and year(int) as parameters.
    Select the necessary columns for ranking and score analysis
    ('name', 'rank', 'scores_overall', 'scores_citations',
    'scores_industry_income', 'scores_international_outlook',
    'scores_research', 'scores_teaching')
    Return the filtered dataset pd.DataFrame
    """
    rank_df = data[['name', 'rank', 'scores_overall', 'scores_citations',
                    'scores_industry_income', 'scores_international_outlook',
                    'scores_research', 'scores_teaching']][:50]
    rank_df['year'] = year
    return rank_df


def top10_ranking_years(data: pd.DataFrame):
    """
    Takes the dataset(pd.DataFrame) as the parameter
    Plots the top10 unversities' ranking from 2016 to
    2023 on the line chart
    Use fig.update_layout() to set title, axes and legend title
    """
    fig = px.line(data,  x='year', y='rank', color='name', markers=True)
    fig.update_yaxes(autorange="reversed")
    fig.update_layout(title='Top 10 University rankings from 2016 to 2023',
                      xaxis_title='Year',
                      yaxis_title='Rankings',
                      legend_title='University Names')
    fig.show()


def residuals_plot(X: pd.DataFrame, Y: pd.DataFrame):
    """
    Takes the X as features and Y as label , both are the pd.DataFrame
    Split the data with test_size = 0.2
    Fit the training data to the visualizer
    Use Ridge regression model to train the inputted data to see the
    accuracy of this model
    ResidualsPlot plots a scatter plot with a histogram on the side
    """
    X_train, X_test, y_train, y_test = train_test_split(X, Y,
                                                        test_size=0.2,
                                                        random_state=42)
    model = Ridge()
    visualizer = ResidualsPlot(model).fit(X_train,
                                          y_train)
    visualizer.score(X_test, y_test)
    visualizer.show()


def linear_regression(X: pd.DataFrame, Y: pd.DataFrame):
    """
    Takes the X as features and Y as label , both are the pd.DataFrame
    Use LinearRegression model to make prediction
    Get the running time to see the efficency of this model
    Return the R^2 score to to the model accuracy
    """
    start_time = time.perf_counter()
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2)
    model = LinearRegression().fit(X_train, Y_train)
    end_time = time.perf_counter()
    run_time = end_time - start_time
    return print(f'R^2 score: {model.score(X_test, Y_test)},\
                 run time: {run_time}')


def pearson_correlation(X: pd.DataFrame, Y: pd.DataFrame):
    """
    Takes the X as features and Y as label , both are the pd.DataFrame
    Use FeatureCorrelation to calculate Pearson correlation
    coefficients between features(different scores)
    Fit the data to the visualizer
    Plot the the bar chart to visualize
    """
    features = list(X)
    visualizer = FeatureCorrelation(labels=features)
    visualizer.fit(X, Y)
    _ = plt.title('Features Correlation with dependent variables')
    visualizer.show()


def rank_2d(X: pd.DataFrame, Y: pd.DataFrame):
    """
    Takes the X as features and Y as label , both are the pd.DataFrame
    Fit the training data to the visualizer
    Plot Rank2D with algorithm Pearson to show the correlation
    between features
    """
    visualizer = Rank2D(algorithm='pearson')
    visualizer.fit(X, Y)
    visualizer.transform(X)
    visualizer.show()


def merged_data_year() -> pd.DataFrame:
    """
    Read and merge the rankings data from multiple CSV files
    for different years.
    Returns a DataFrame with selected columns: 'year',
    'stats_female_male_ratio', 'rank'.
    """
    csv_files = ['2016_rankings.csv', '2017_rankings.csv',
                 '2018_rankings.csv', '2019_rankings.csv',
                 '2020_rankings.csv', '2021_rankings.csv',
                 '2022_rankings.csv', '2023_rankings.csv']
    merged_data = pd.DataFrame()

    for file in csv_files:
        year = int(file[:4])
        data = pd.read_csv(file)
        data['year'] = year
        merged_data = pd.concat([data, merged_data])

    return merged_data[['year', 'stats_female_male_ratio', 'rank']].copy()


def ratio_citation_correlation(data: pd.DataFrame, year: int):
    """
    Calculate and plot the correlation between citation scores
    and student-staff ratio for a given year.
    """
    scores_citations = data['scores_citations']
    stats_student_staff_ratio = data['stats_student_staff_ratio']
    data['stats_student_staff_ratio'] = pd.to_numeric(
        data['stats_student_staff_ratio'], errors='coerce')
    correlation_coefficient = round(data['scores_citations'].corr(data
                                    ['stats_student_staff_ratio']), 3)
    plt.scatter(stats_student_staff_ratio, scores_citations)
    plt.xlabel('Student-Staff Ratio')
    plt.ylabel('Citation Scores')
    plt.title(f'Correlation Coefficient:\
    {correlation_coefficient} Relationship\
    between Citation Scores and\
    Student-Staff Ratio(Year: {year})')
    plt.show()


def plot_mean_gender_ratio(data: pd.DataFrame):
    """
    Calculate and plot the mean female-to-male ratio for the top 100
    universities from 2016 to 2023.
    """
    data[['female_ratio', 'male_ratio']] = data[
        'stats_female_male_ratio'].str.split(':', expand=True)
    data['female_ratio'] = data['female_ratio'].fillna(1).astype(int)
    data['male_ratio'] = data['male_ratio'].fillna(1).astype(int)
    data['female_to_male_ratio'] = data['female_ratio'] / data['male_ratio']
    data['rank'] = pd.to_numeric(data['rank'], errors='coerce')
    data = data[data['rank'] <= 100]
    mean_ratio_by_year = data.groupby('year')['female_to_male_ratio'].mean()
    plt.figure(figsize=(10, 6))
    plt.plot(mean_ratio_by_year.index, mean_ratio_by_year.values,
             marker='o')
    plt.xlabel('Year', fontsize=12)
    plt.ylabel('Mean Female to Male Ratio', fontsize=12)
    plt.title('Mean Female to Male Ratio for Top\
    100 Universities (2016-2023)', fontsize=14)
    plt.grid(True)
    plt.tight_layout()
    plt.show()


def plot_gender_correlation(data: pd.DataFrame, year: int):
    """
    Calculate and plot the correlation between female-to-male ratio and
    ranking for a specific year.
    """
    data = data[data['year'] == year]
    data = data[['stats_female_male_ratio', 'rank']].copy()
    data[['female_ratio', 'male_ratio']] = (
        data['stats_female_male_ratio'].str.split(':', expand=True))
    data['female_ratio'] = data['female_ratio'].fillna(1).astype(int)
    data['male_ratio'] = data['male_ratio'].fillna(1).astype(int)
    data['female_to_male_ratio'] = data['female_ratio'] / data['male_ratio']
    data['rank'] = pd.to_numeric(data['rank'], errors='coerce')
    correlation_coefficient = data['female_to_male_ratio'].corr(data['rank'])
    plt.figure(figsize=(6, 4))
    plt.scatter(data['female_to_male_ratio'],
                data['rank'], alpha=0.5)
    plt.xlabel('Female to Male Ratio', fontsize=12)
    plt.ylabel('Ranking', fontsize=12)
    plt.title('Correlation Coefficient: {:.3f} (Year {})'.format
              (correlation_coefficient, year), fontsize=14)
    plt.grid(True)
    plt.tight_layout()
    plt.show()


def count_universities_by_country(df: pd.DataFrame) -> pd.DataFrame:
    """
    Count the number of universities by country.
    Args:
    - df (pd.DataFrame): DataFrame containing the number of top 200
    universities in each country.
    Returns:
    - pd.DataFrame: DataFrame with country and university count.
    """
    df_gr = df["location"].value_counts().reset_index()
    df_gr = df_gr.rename(columns={"location": "Country",
                                  "count": "Number"})
    df_gr["Country"] = df_gr["Country"].replace("United States",
                                                "United States of America")
    return df_gr


def plot_world_map(university_counts: pd.DataFrame, year: str) -> None:
    """
    Plot a world map to visualize the number of universities in each country.
    Args:
    - university_counts (pd.DataFrame): DataFrame containing the number of top
    200 universities in each country.
    - year (str): Year of the data.
    Returns:
    - A world map.
    """
    world = gpd.read_file(gpd.datasets.get_path("naturalearth_lowres"))
    world_blank = world.copy()
    world_blank["Number"] = np.nan
    world = world.merge(university_counts, left_on="name",
                        right_on="Country", how="left")
    fig, ax = plt.subplots(figsize=(12, 8), dpi=100)
    world_blank.plot(color="lightgray", linewidth=0.8, ax=ax,
                     edgecolor="0.8")
    cmap = plt.cm.get_cmap("Blues")
    cmap.set_under("lightgray")
    world.plot(column="Number", cmap="Blues", linewidth=0.8, ax=ax,
               edgecolor="0.8", legend=True, legend_kwds={"shrink": 0.5})
    ax.set_title("Number of Universities in Each Country in " + year)
    plt.show()


def merge_gdp_ranking(ranking: pd.DataFrame,
                      gdp: pd.DataFrame, year: str) -> pd.DataFrame:
    """
    Merge the university ranking and GDP data for a specific year.
    Args:
    - ranking (pd.DataFrame): DataFrame with country and university count.
    - gdp (pd.DataFrame): DataFrame with country and GDP data.
    - year (str): Year of the data.
    Returns:
    - pd.DataFrame: Merged DataFrame containing country, university count,
    and GDP.
    """
    merged_gdp = pd.merge(ranking, gdp[["Country", year]],
                          on="Country", how="inner")
    return merged_gdp


def scatter_gdp_ranking(merged_gdp_ranking: pd.DataFrame, year: str) -> None:
    """
    Create a scatter plot to show the correlation between GDP and the number
    of universities.
    Args:
    - merged_gdp_ranking (pd.DataFrame): Merged DataFrame containing country,
    university count, and GDP.
    - year (str): Year of the data.
    Returns:
    A scatter plot
    """
    # Create a scatterplot
    plt.figure(figsize=(15, 10))
    plt.scatter(merged_gdp_ranking[year], merged_gdp_ranking["Number"],
                alpha=0.7, s=100)
    plt.xlabel("GDP")
    plt.ylabel("Number of Universities")
    plt.title("Correlation Between GDP and Number of Universities in " + year)
    plt.grid(True)
    # Calculate the best-fit line
    x = merged_gdp_ranking[year]
    y = merged_gdp_ranking["Number"]
    coeffs = np.polyfit(x, y, 1)
    best_fit_line = np.polyval(coeffs, x)
    # Plot the best-fit line
    plt.plot(x, best_fit_line, color="red", linewidth=2)
    # Label each point with the country's name.
    for i, row in merged_gdp_ranking.iterrows():
        country = row["Country"]
        plt.text(row[year], row["Number"], country, fontsize=8,
                 ha="center", va="bottom")
    corr_coeff, _ = pearsonr(x, y)
    plt.annotate(f"Correlation Coefficient: {corr_coeff:.2f}", (0.05, 0.95),
                 xycoords="axes fraction", fontsize=10, ha="left", va="top")
    plt.show()


# Testing
# Test machine learning using neural network
def neural_network(X: pd.DataFrame, Y: pd.DataFrame):
    """
    Takes the X as features and Y as label , both are the pd.DataFrame
    Split the data with test_size = 0.2
    Use neural network to make prediction on the inputted data
    Get the running time to see the efficency of this model
    Return the testing and training accuracy and run time
    """
    train_acc = []
    test_acc = []
    run_time = []
    start_time = time.perf_counter()
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y,
                                                        test_size=0.2,
                                                        random_state=42)
    m = MLPClassifier().fit(X_train, Y_train)
    end_time = time.perf_counter()
    train_acc.append(m.score(X_train, Y_train))
    test_acc.append(m.score(X_test, Y_test))
    run_time.append(end_time - start_time)
    return print(f'training accuracy: {train_acc},\
                 testing accuracy: {test_acc},\
                 run time: {run_time}')


def test_ratio_citation_correlation():
    """
    Create a sample DataFrame with citation scores and student-staff ratios
    """
    data = pd.DataFrame({
        'scores_citations': [90, 85, 95, 80, 70],
        'stats_student_staff_ratio': [10, 8, 12, 9, 11]
    })
    year = 2023
    ratio_citation_correlation(data, year)


def test_plot_mean_gender_ratio():
    """
    Create a sample DataFrame with year, female-to-male ratio, and rank
    """
    data = pd.DataFrame({
        'year': [2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023],
        'stats_female_male_ratio': ['50:50', '60:40', '55:45', '70:30',
                                    '40:60', '65:35', '75:25', '80:20'],
        'rank': [1, 2, 3, 4, 5, 6, 7, 8]
    })
    plot_mean_gender_ratio(data)


def test_plot_gender_correlation():
    """
    Create a sample DataFrame with year, female-to-male ratio, and rank
    """
    data = pd.DataFrame({
        'year': [2016, 2016, 2016, 2016, 2016],
        'stats_female_male_ratio': ['50:50', '60:40', '55:45', '70:30',
                                    '40:60'],
        'rank': [1, 2, 3, 4, 5]
    })
    plot_gender_correlation(data, 2016)


def test_plot_world_map() -> None:
    """
    Tests the plot_world_map.
    """
    # Create a small dataset for testing
    data = {
        'Country': ["China", "Argentina", "Spain"],
        'Number': [10, 5, 7]
    }
    df = pd.DataFrame(data)
    # Call the plot_world_map function
    plot_world_map(df, "testing")


def test_scatter_gdp_ranking() -> None:
    """
    Tests the scatter_gdp_ranking function.
    """
    # Create a small dataset for testing
    merged_gdp_ranking = pd.DataFrame({
        "Country": ["China", "Argentina", "Spain"],
        "Number": [10, 5, 7],
        "testing": [1000, 500, 700],
    })
    scatter_gdp_ranking(merged_gdp_ranking, "testing")


def main():
    # Clean the datasets - drop NAs
    data_2016: pd.DataFrame = pd.read_csv(RANKINGS_2016).dropna()
    data_2017: pd.DataFrame = pd.read_csv(RANKINGS_2017).dropna()
    data_2018: pd.DataFrame = pd.read_csv(RANKINGS_2018).dropna()
    data_2019: pd.DataFrame = pd.read_csv(RANKINGS_2019).dropna()
    data_2020: pd.DataFrame = pd.read_csv(RANKINGS_2020).dropna()
    data_2021: pd.DataFrame = pd.read_csv(RANKINGS_2021).dropna()
    data_2022: pd.DataFrame = pd.read_csv(RANKINGS_2022).dropna()
    data_2023: pd.DataFrame = pd.read_csv(RANKINGS_2023).dropna()

    # Get Top50 university from 2016 to 2023
    df_2016 = top50_scores(data_2016, 2016)
    df_2017 = top50_scores(data_2017, 2017)
    df_2018 = top50_scores(data_2018, 2018)
    df_2019 = top50_scores(data_2019, 2019)
    df_2020 = top50_scores(data_2020, 2020)
    df_2021 = top50_scores(data_2021, 2021)
    df_2022 = top50_scores(data_2022, 2022)
    df_2023 = top50_scores(data_2023, 2023)

    # Combine the datasets and process the data type
    combined_df = pd.concat([df_2016, df_2017, df_2018, df_2019,
                             df_2020, df_2021, df_2022, df_2023])
    combined_df['rank'] = combined_df['rank'].apply(
                          lambda x: "".join([re.sub('^=', '', s) for s in x]))
    combined_df['rank'] = combined_df['rank'].astype('float64')
    combined_df['scores_overall'] = combined_df['scores_overall'
                                                ].astype('float64')
    combined_df['year'] = combined_df['year'].astype('int64')
    # Get Top10 university of from 2016 to 2023
    combined_df_top10 = pd.concat([df_2016[:10], df_2017[:10],
                                   df_2018[:10], df_2019[:10],
                                   df_2020[:10], df_2021[:10],
                                   df_2022[:10], df_2023[:10]])

    # Plot the Top10 university rank 2016-2023
    top10_ranking_years(combined_df_top10)

    # Visualize the model accuracy and distribution
    x = combined_df.drop(columns=['name', 'rank',
                                  'year', 'scores_overall'], axis=1)
    y = combined_df['rank']
    residuals_plot(x, y)

    # Get the correlation coefficient of featrues(different scores)
    x_score = combined_df.drop(columns=['name', 'rank', 'year'], axis=1)
    pearson_correlation(x, y)
    rank_2d(x_score, y)

    # Merge data from 2016-2023
    merged_data = merged_data_year()

    # Plot a graph that shows the trends of the
    # mean of female:male ratio from 2016-2023
    plot_mean_gender_ratio(merged_data)

    # Plot a graph that shows the female:male
    # ratio and university ranking correlation
    plot_gender_correlation(merged_data, 2016)
    plot_gender_correlation(merged_data, 2017)
    plot_gender_correlation(merged_data, 2018)
    plot_gender_correlation(merged_data, 2019)
    plot_gender_correlation(merged_data, 2020)
    plot_gender_correlation(merged_data, 2021)
    plot_gender_correlation(merged_data, 2022)
    plot_gender_correlation(merged_data, 2023)

    # Plot a graph that shows the student:staff
    # ratio and citation score correlation
    ratio_citation_correlation(data_2016, 2016)
    ratio_citation_correlation(data_2017, 2017)
    ratio_citation_correlation(data_2018, 2018)
    ratio_citation_correlation(data_2019, 2019)
    ratio_citation_correlation(data_2020, 2020)
    ratio_citation_correlation(data_2021, 2021)
    ratio_citation_correlation(data_2022, 2022)
    ratio_citation_correlation(data_2023, 2023)

    # Read the top 200 universities in the rankings from 2016 to 2023.
    data_2016_top200 = data_2016.head(200)
    data_2017_top200 = data_2017.head(200)
    data_2018_top200 = data_2018.head(200)
    data_2019_top200 = data_2019.head(200)
    data_2020_top200 = data_2020.head(200)
    data_2021_top200 = data_2021.head(200)
    data_2022_top200 = data_2022.head(200)
    data_2023_top200 = data_2023.head(200)

    # Create a DataFrame that corresponds the country name to the number of
    # universities.
    university_counts_2016 = count_universities_by_country(data_2016_top200)
    university_counts_2017 = count_universities_by_country(data_2017_top200)
    university_counts_2018 = count_universities_by_country(data_2018_top200)
    university_counts_2019 = count_universities_by_country(data_2019_top200)
    university_counts_2020 = count_universities_by_country(data_2020_top200)
    university_counts_2021 = count_universities_by_country(data_2021_top200)
    university_counts_2022 = count_universities_by_country(data_2022_top200)
    university_counts_2023 = count_universities_by_country(data_2023_top200)

    # Create a world map to show the number of universities in each country.
    plot_world_map(university_counts_2016, "2016")
    plot_world_map(university_counts_2017, "2017")
    plot_world_map(university_counts_2018, "2018")
    plot_world_map(university_counts_2019, "2019")
    plot_world_map(university_counts_2020, "2020")
    plot_world_map(university_counts_2021, "2021")
    plot_world_map(university_counts_2022, "2022")
    plot_world_map(university_counts_2023, "2023")

    # Read and filter each country's GDP from 2016 to 2020.
    gdp_2016_2020: pd.DataFrame = pd.read_csv(GDP_2016_2020).dropna()

    # Create a DataFrame that corresponds the number of universites to
    # GDP of a country.
    gdp_2016 = merge_gdp_ranking(university_counts_2016, gdp_2016_2020, "2016")
    gdp_2017 = merge_gdp_ranking(university_counts_2017, gdp_2016_2020, "2017")
    gdp_2018 = merge_gdp_ranking(university_counts_2018, gdp_2016_2020, "2018")
    gdp_2019 = merge_gdp_ranking(university_counts_2019, gdp_2016_2020, "2019")
    gdp_2020 = merge_gdp_ranking(university_counts_2020, gdp_2016_2020, "2020")

    # Create a scatter plot to show the correlation between GDP and the
    # number of universities from 2016 to 2020.
    scatter_gdp_ranking(gdp_2016, "2016")
    scatter_gdp_ranking(gdp_2017, "2017")
    scatter_gdp_ranking(gdp_2018, "2018")
    scatter_gdp_ranking(gdp_2019, "2019")
    scatter_gdp_ranking(gdp_2020, "2020")

    # TESTING
    # Tests the Top1 university ranking change
    test_df = pd.concat([df_2016[:1], df_2017[:1],
                         df_2018[:1], df_2019[:1],
                         df_2020[:1], df_2021[:1],
                         df_2022[:1], df_2023[:1]])
    top10_ranking_years(test_df)

    # Tests the accuracy of machine learning model
    test_df_ml = pd.concat([df_2016[:10], df_2017[:10],
                            df_2018[:10], df_2019[:10],
                            df_2020[:10], df_2021[:10],
                            df_2022[:10], df_2023[:10]])
    test_df_ml['rank'] = test_df_ml['rank'].apply(
                            lambda x: "".join([re.sub(
                                                '^=', '', s) for s in x]))
    test_df_ml['rank'] = test_df_ml['rank'].astype('float64')
    test_df_ml['scores_overall'] = test_df_ml['scores_overall'
                                              ].astype('float64')
    test_df_ml['year'] = test_df_ml['year'].astype('int64')
    x = test_df_ml.drop(columns=['name', 'rank',
                                 'year', 'scores_overall'], axis=1)
    y = test_df_ml['rank']
    linear_regression(x, y)
    neural_network(x, y)

    # Tests correlation coefficient changes between scores and rank
    # with smaller dataset
    pearson_correlation(x, y)

    # Tests the line graph of the female : male ratio mean
    test_plot_mean_gender_ratio()

    # Tests correlation coefficient bewteen female:male ratio
    # and the university ranking, plot the scatter diagram
    # by using a smaller data set.
    test_plot_gender_correlation()

    # Tests correlation coefficient between student: staff ratio
    # and citation score, plot the scatter diagram by using a
    # smaller data set.
    test_ratio_citation_correlation()

    # Tests the plot_world_map and scatter_gdp_ranking function with a small
    # dataset.
    test_plot_world_map()
    test_scatter_gdp_ranking()


if __name__ == "__main__":
    main()