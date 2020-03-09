<template>
  <v-app>
    <v-content>
      <v-card>
        <v-card-title>
          <v-row>
            <v-col cols="12" sm="6">
              <v-text-field
                      v-model="search"
                      label="Search"
                      single-line
                      hide-details
              ></v-text-field>
            </v-col>
            <v-col cols="12" sm="6">

              <v-menu
                      v-model="datePicker"
                      :close-on-content-click="false"
                      transition="scale-transition"
                      offset-y
                      max-width="290px"
                      min-width="290px"
              >
                <template v-slot:activator="{ on }">
                  <v-text-field
                          v-model="dateRangeText"
                          label="Date range"
                          readonly
                          @click="datePicker=true"
                          v-on="on"
                  ></v-text-field>
                </template>
                <v-date-picker
                        v-model="dates"
                        range
                        no-title
                        scrollable
                        v-show="datePicker"
                        @change="datePicker = dates.length != 2"
                ></v-date-picker>
              </v-menu>
            </v-col>
          </v-row>
        </v-card-title>
        <v-data-table
                :headers="headers"
                :items="logs"
                :search="search"
                :options.sync="pagination"
                :server-items-length="totalItems"
                :loading="loading"
                multi-sort
                dense
        >
          <template v-slot:item.date="{ item }">
            <span>{{new Date(item.date).toLocaleString()}}</span>
          </template>
        </v-data-table>
      </v-card>
    </v-content>
  </v-app>
</template>

<script>
  import axios from 'axios';

  export default {
    name: 'App',

    data: () => ({
      search: '',
      lastSearch: '',
      logs: [],
      stats: {},
      totalItems: 0,
      timeout: null,
      datePicker: false,
      dates: [new Date().toISOString().substr(0, 10), new Date().toISOString().substr(0, 10)],
      headers: [
        { text: 'IP address', align: 'start', value: 'ip' },
        { text: 'Date', value: 'date' },
        { text: 'HTTP method', value: 'method' },
        { text: 'URI path', value: 'path' },
        { text: 'Response code', value: 'response_code' },
        { text: 'Response content length (B)', value: 'response_size' },
      ],
      pagination: {
        page: 1,
        itemsPerPage: 10
      },
      loading: true,
    }),
    methods: {
      getData() {
        if (this.dates.length < 2) return;
        this.loading = true;
        const limit = (this.pagination.itemsPerPage | 10),
                offset = ((this.pagination.page | 1) - 1) * limit,
                filters = this.getFilters();
        axios.get(`/api/v1/logs?limit=${limit}&offset=${offset}${filters}`)
                .then((res)=>{
                  this.loading = false;
                  const data = res.data;
                  this.totalItems = data.count;
                  this.logs = data.results.data.map((el) => {
                    return {
                      ...el,
                      date: new Date(el.date)
                    }
                  });
                }).catch(() => {
          this.loading = false;
        });
      },
      getFilters() {
        const query = this.search.trim(), ordering = this.pagination.sortBy.map((val, index) => {
          const byDesk = this.pagination.sortDesc;
          if (byDesk != undefined && byDesk[index]) return `-${val}`;
          return val;
        });
        const [dateFrom, dateTo] = [...this.dates].sort();
        return `&search=${query}&ordering=${ordering}&date_from=${dateFrom}&date_to=${dateTo}`
      }
    },
    computed: {
      params() {
        return {
          ...this.pagination,
          dates: this.dates
        }
      },
      dateRangeText () {
        return [...this.dates].sort().join(' ~ ')
      },
    },
    watch: {
      params: {
        handler() {
          this.getData();
        },
        deep: true
      },
      search: {
        handler() {
          const query = this.search.trim();
          if (this.lastSearch == query) return;
          this.lastSearch = query;
          if (this.timeout) clearTimeout(this.timeout);
          this.timeout = setTimeout(this.getData, 400);
        },
        deep: true
      },
    }
  };
</script>
